//==========================================================
// scoreboard.sv
//este bloque es un proceso con memoria: vive toda la
// simulacion sosteniendo, por dispositivo destino, la cola de envios que
// todavia no encontraron su llegada. Esa cola emula la FIFO fisica de
// cada dispositivo
//=============================================================================

class scoreboard #(
  parameter int       bits      = 16,
  parameter int       drvrs     = 4,
  parameter bit [7:0] broadcast = 8'hFF
);

  // Entradas: una mailbox por cada mitad de la historia.
  protected mailbox #(trans_bus #(bits, drvrs)) agnt_sb_mbx;  // intencion (agente/driver)
  protected mailbox #(trans_sb #(bits))  chkr_sb_mbx;  // hecho     (checker)

  // Una cola de pendientes por dispositivo destino.
  protected trans_bus #(bits, drvrs) pendientes[drvrs][$];

  protected trans_bus #(bits, drvrs) invalidas[$];

  typedef struct {
    time        t_envio;
    bit [7:0]   origen;
    bit [7:0]   destino;
    time        t_recibido;
    time        retraso;
    resultado_e resultado;
  } fila_reporte_t;

  protected fila_reporte_t reporte[$];
  protected string         csv_path;

  function new(mailbox #(trans_bus #(bits, drvrs)) agnt_sb_mbx,
               mailbox #(trans_sb #(bits))  chkr_sb_mbx,
               string csv_path = "reporte_paquetes.csv");
    this.agnt_sb_mbx = agnt_sb_mbx;
    this.chkr_sb_mbx = chkr_sb_mbx;
    this.csv_path    = csv_path;
  endfunction

  // Arranca los dos escuchas como procesos independientes: llegan por
  // canales distintos, en cualquier orden relativo, sin que uno deba
  // bloquear al otro.
  task run();
    fork
      escuchar_envios();
      escuchar_llegadas();
    join_none
  endtask

  //------------------------------------------
  // Lado "esperado": el driver confirma que un push fue aceptado de
  // verdad. 
  //----------------------------------------------------
    protected task escuchar_envios();
    trans_bus #(bits, drvrs) tb;
    forever begin
      agnt_sb_mbx.get(tb);

      if (tb.destino == broadcast) begin
        // Un solo envio, un receptor por dispositivo: mismo handle en
        // todas las colas
        // El emisor no se envia a el mismo
        foreach (pendientes[i])
          if (i != tb.origen)
            pendientes[i].push_back(tb);
      end
      else if (tb.destino < drvrs) begin
        pendientes[tb.destino].push_back(tb);
      end
      else begin
        // Direccion que no corresponde a ningun dispositivo real
        invalidas.push_back(tb);
      end
    end
  endtask


    // Palabra que el driver puso en D_pop para este trans_bus: byte alto =
  // direccion (broadcast si es BROADCAST), byte bajo = payload. 
  protected function bit [bits-1:0] palabra_esperada(trans_bus #(bits, drvrs) tb);
    bit [7:0] dir;
    dir = (tb.tipo == BROADCAST) ? broadcast : tb.destino[7:0];
    return {dir, tb.payload[bits-9:0]};
  endfunction


  //-----------------------------------
  // Lado "actual": checker.sv confirma que algo llego. UNDERFLOW no
  // tiene un trans_bus real detras 
  //-----------------------------------------------
  protected task escuchar_llegadas();
    trans_sb  #(bits) tsb;
    trans_bus #(bits, drvrs) tb;
    int       d;
    int       idx;
    forever begin
      chkr_sb_mbx.get(tsb);

      if (tsb.resultado == UNDERFLOW) begin
        agregar_fila(0, 0, tsb.destino, tsb.t_recibido, 0, UNDERFLOW);
        continue;
      end

      if (tsb.destino >= drvrs) begin
        $error("scoreboard: trans_sb con destino fuera de rango (%0d)", tsb.destino);
        agregar_fila(0, 0, tsb.destino, tsb.t_recibido, 0, PERDIDO);
        continue;
      end

      d = tsb.destino;

      // Buscar, entre los pendientes de este destino, el primero que ya
      // se transmitio (t_envio != 0) y cuya palabra coincide con la que
      // llego. no hay orden como tal.
      idx = -1;
      for (int j = 0; j < pendientes[d].size(); j++) begin
        if (pendientes[d][j].t_envio != 0 &&
            palabra_esperada(pendientes[d][j]) == tsb.dato_enviado) begin
          if (idx < 0 || pendientes[d][j].t_envio < pendientes[d][idx].t_envio)
            idx = j;
        end
      end

      if (idx < 0) begin
        $error("scoreboard: llegada a destino %0d (dato 0x%0h) sin envio pendiente que coincida",
               d, tsb.dato_enviado);
        continue;
      end

      tb = pendientes[d][idx];
      pendientes[d].delete(idx);
      tsb.cerrar_con_envio(tb.t_envio);
      agregar_fila(tb.t_envio, tb.origen, d, tsb.t_recibido,
                   tsb.t_recibido - tb.t_envio, COMPLETADO);
    end
  endtask

  // Fila que no aplica (t_envio o t_recibido desconocido) se deja en 0.
  protected function void agregar_fila(time t_envio, bit [7:0] origen,
                                        bit [7:0] destino, time t_recibido,
                                        time retraso, resultado_e resultado);
    fila_reporte_t fila;
    fila.t_envio    = t_envio;
    fila.origen     = origen;
    fila.destino    = destino;
    fila.t_recibido = t_recibido;
    fila.retraso    = retraso;
    fila.resultado  = resultado;
    reporte.push_back(fila);
  endfunction


  // GNUplot lee ese CSV por separado; este
  // bloque no genera ningun grafico.
  //---------------------------------------------------------------------
  function void reportar_final();
    int fd;

    foreach (pendientes[i]) begin
      while (pendientes[i].size() > 0) begin
        trans_bus #(bits, drvrs) tb = pendientes[i].pop_front();
        agregar_fila(tb.t_envio, tb.origen, i, 0, 0, PERDIDO);
      end
    end

    // Paquetes INVALIDA: se reportan aca porque el driver ya les puso t_envio
    foreach (invalidas[k])
      agregar_fila(invalidas[k].t_envio, invalidas[k].origen,
                   invalidas[k].destino, 0, 0, PERDIDO);

    fd = $fopen(csv_path, "w");
    if (fd == 0) begin
      $error("scoreboard: no se pudo abrir %s", csv_path);
      return;
    end

    $fdisplay(fd, "t_envio,origen,destino,t_recibido,retraso,resultado");
    foreach (reporte[i]) begin
      $fdisplay(fd, "%0t,%0d,%0d,%0t,%0t,%s",
                reporte[i].t_envio, reporte[i].origen, reporte[i].destino,
                reporte[i].t_recibido, reporte[i].retraso,
                reporte[i].resultado.name());
    end
    $fclose(fd);
  endfunction

  function int pendientes_totales();
    int total = 0;
    foreach (pendientes[i]) total += pendientes[i].size();
    foreach (invalidas[k]) if (invalidas[k].t_envio == 0) total++;
    return total;
  endfunction

endclass
