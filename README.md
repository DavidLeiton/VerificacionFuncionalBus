# Proyecto 1: Verificación Funcional de Bus con Arbitraje Round-Robin

## Integrantes

| Nombre | Carné |
| :--- | :--- |
| Wilbert Alonso Román Rodríguez | 2019042296 |
| David Leiton | 2021103803 |

## Resumen del Proyecto
Este proyecto consiste en el diseño e implementación de un ambiente de verificación funcional basado en capas. El dispositivo bajo prueba (DUT) es un bus de datos full-mesh que opera con un controlador de arbitraje tipo round-robin y que integra memorias FIFO para la comunicación entre dispositivos. Se desarrollará un ambiente completo en SystemVerilog que incluye Test, Generador, Agente, Driver, Monitor, Checker y Scoreboard para emular el comportamiento de las interfaces e inyectar estímulos de manera automatizada.

## Objetivos
* Verificar funcionalmente el DUT `prll_bs_gnrtr_n_rbtr`.
* Demostrar la entrega correcta de los paquetes de datos.
* Validar la rotación adecuada del árbitro round-robin.
* Corroborar el manejo de direcciones inválidas y direcciones de broadcast.
* Evaluar el comportamiento del bus bajo múltiples configuraciones de cantidad de dispositivos (`drvrs`), profundidad de FIFO (`depth`) y ancho de payload (`bits`).

## Jerarquía del Repositorio

* **`rtl/`**: Contiene el código fuente del hardware sintetizable, incluyendo el archivo `Library.sv` con el prototipo del DUT y el diseño de la FIFO.
* **`tb/`**: Directorio con el código de verificación en SystemVerilog (transacciones, clases de transactores, ambiente y el módulo superior del `testbench`).
* **`docs/`**: Documentación del proyecto, lineamientos y el archivo de plan de pruebas.
* **`scripts/`**: Archivos para el procesamiento de datos y la configuración para generar gráficas.
* **`results/`**: Carpeta destinada a almacenar la salida de la simulación, reportes y gráficas.

## Método de Compilación y Prueba

El proyecto utiliza un flujo de trabajo híbrido diseñado para optimizar el desarrollo colaborativo:
1. **Control de Versiones:** El código fuente se edita de manera local en el sistema operativo Linux (Ubuntu) y la coordinación del trabajo en equipo se gestiona estrictamente a través de un repositorio en Github.
2. **Simulación:** La compilación y ejecución del código orientado a objetos se realiza utilizando EDA Playground. El módulo principal utiliza directivas para incluir y estructurar los múltiples archivos del diseño de pruebas en capas.
3. **Análisis de Resultados:** Las simulaciones exportan los datos consolidados por el Scoreboard. Posteriormente, se procesan los resultados de forma local utilizando comandos para visualizar el histograma de latencias y comprobar la cobertura mediante GNUplot.
