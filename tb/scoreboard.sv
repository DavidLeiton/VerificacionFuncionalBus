//=============================================================================
// scoreboard.sv
//
// Empareja cada trans_bus enviado (intencion) con su trans_sb
// correspondiente (hecho consumado, armado por checker.sv) y produce el
// reporte de paquetes exigido como entregable.
//
// A diferencia de trans_bus/trans_sb (nacen completos y se cierran una
// unica vez), este bloque es un PROCESO con memoria: vive toda la
// simulacion sosteniendo, por dispositivo destino, la cola de envios que
// todavia no encontraron su llegada. Esa cola emula la FIFO fisica de
// cada dispositivo, por eso el orden de llegada alcanza para resolver el
// matching sin inventar un ID de transaccion que no existe en el
// protocolo real.
//
// DEPENDENCIAS (actualizar aca si cambian del otro lado):
//   trans_bus.sv : se asume con campos origen, destino, t_envio.
//   trans_sb.sv  : se asume con campo destino, t_recibido, resultado, y
//                  metodo cerrar_con_envio(time t_tx).
//   resultado_e  : debe incluir PERDIDO ademas de COMPLETADO/UNDERFLOW
//                  (los dos que ya produce checker.sv). PERDIDO lo genera
//                  unicamente este archivo.
//   En EDAPlayground, asegurate de que trans_bus.sv y trans_sb.sv esten
//   antes que este archivo en el orden de compilacion.
//=============================================================================

class scoreboard #(
  parameter int       drvrs     = 4,
  parameter bit [7:0] broadcast = 8'hFF
);

  // Entradas: una mailbox por cada mitad de la historia.
  protected mailbox #(trans_bus) agnt_sb_mbx;  // intencion (agente/driver)
  protected mailbox #(trans_sb)  chkr_sb_mbx;  // hecho     (checker)

  // Una cola de pendientes por dispositivo destino.
  protected trans_bus pendientes[drvrs][$];

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

  function new(mailbox #(trans_bus) agnt_sb_mbx,
               mailbox #(trans_sb)  chkr_sb_mbx,
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

  //---------------------------------------------------------------------
  // Lado "esperado": el driver confirma que un push fue aceptado de
  // verdad. Aca se decide, sin esperar nada, si el envio tiene chance de
  // llegar (se encola) o nunca la va a tener (PERDIDO inmediato).
  //---------------------------------------------------------------------
  protected task escuchar_envios();
    trans_bus tb;
    forever begin
      agnt_sb_mbx.get(tb);

      if (tb.destino == broadcast) begin
        // Un solo envio, un receptor por dispositivo: mismo handle en
        // todas las colas, cada una se resuelve despues por separado.
        foreach (pendientes[i]) pendientes[i].push_back(tb);
      end
      else if (tb.destino < drvrs) begin
        pendientes[tb.destino].push_back(tb);
      end
      else begin
        // Direccion que no corresponde a ningun dispositivo real: no
        // existe FIFO fisica que algun dia lo entregue.
        agregar_fila(tb.t_envio, tb.origen, tb.destino, 0, 0, PERDIDO);
      end
    end
  endtask

  //---------------------------------------------------------------------
  // Lado "actual": checker.sv confirma que algo llego. UNDERFLOW no
  // tiene un trans_bus real detras (fue una lectura sin dato pendiente),
  // asi que se reporta directo, sin tocar las colas.
  //---------------------------------------------------------------------
  protected task escuchar_llegadas();
    trans_sb  tsb;
    trans_bus tb;
    forever begin
      chkr_sb_mbx.get(tsb);

      if (tsb.resultado == UNDERFLOW) begin
        agregar_fila(0, 0, tsb.destino, tsb.t_recibido, 0, UNDERFLOW);
        continue;
      end

      if (pendientes[tsb.destino].size() == 0) begin
        $error("scoreboard: trans_sb para destino %0d sin envio pendiente que matchear",
               tsb.destino);
        continue;
      end

      tb = pendientes[tsb.destino].pop_front();
      tsb.cerrar_con_envio(tb.t_envio);
      agregar_fila(tb.t_envio, tb.origen, tsb.destino, tsb.t_recibido,
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

  //---------------------------------------------------------------------
  // Cierre de simulacion: cualquier pendiente que sobreviva hasta aca es
  // un envio que nunca encontro su llegada (PERDIDO), y se vuelca todo
  // el reporte acumulado al CSV. GNUplot lee ese CSV por separado; este
  // bloque no genera ningun grafico.
  //---------------------------------------------------------------------
  function void reportar_final();
    int fd;

    foreach (pendientes[i]) begin
      while (pendientes[i].size() > 0) begin
        trans_bus tb = pendientes[i].pop_front();
        agregar_fila(tb.t_envio, tb.origen, tb.destino, 0, 0, PERDIDO);
      end
    end

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

endclass
