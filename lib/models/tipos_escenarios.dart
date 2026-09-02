class ScenariosBank {
  static final List<Map<String, dynamic>> todosLosEscenarios = [
    // --- SUPERVISOR HSEQ ---
    {
      "role": "Supervisor HSEQ",
      "nivel": 1,
      "title": "Fuga de Gas Diésel en Galería",
      "description": "Se detecta un incremento inusual de Monóxido de Carbono (CO) en la galería principal.",
      "option_a": "Continuar con la ventilación secundaria y esperar la siguiente guardia.",
      "option_b": "Evacuar inmediatamente al personal y activar el protocolo de ventilación de emergencia.",
      "option_c": "Reducir la velocidad del motor del dumper para generar menos gas.",
      "correct_option": 1,
      "feedback": "Ante la presencia de concentraciones críticas de CO, la evacuación y ventilación inmediata son obligatorias para preservar la vida."
    },
    {
      "role": "Supervisor HSEQ",
      "nivel": 2,
      "title": "Derrame de Cianuro en Planta de Lixiviación",
      "description": "Una válvula defectuosa causa un goteo constante de solución cianurada cerca de la pileta.",
      "option_a": "Cubrir con arena seca y continuar la inspección al final del turno.",
      "option_b": "Aislar la zona, aplicar hipoclorito de sodio para neutralizar y notificar al comité HSEQ.",
      "option_c": "Lavar la zona con agua a alta presión hacia el canal pluvial.",
      "correct_option": 1,
      "feedback": "El cianuro debe neutralizarse químicamente antes de limpiar; lavar con agua puede contaminar efluentes externos."
    },
    {
      "role": "Supervisor HSEQ",
      "nivel": 3,
      "title": "Falla en Tablero de Alta Tensión",
      "description": "El tablero de la subestación subterránea presenta chispas intermedias.",
      "option_a": "Bloquear el equipo (LOTO) y llamar al electricista certificado.",
      "option_b": "Usar un extintor de agua pulverizada para enfriar el tablero.",
      "option_c": "Reiniciar el disyuntor principal de forma manual.",
      "correct_option": 0,
      "feedback": "El protocolo LOTO (Lockout/Tagout) evita arcos eléctricos fatales en tableros de alta tensión."
    },
    {
      "role": "Supervisor HSEQ",
      "nivel": 4,
      "title": "Inestabilidad en el Talud Norte",
      "description": "El radar de deformación detecta grietas de tracción aceleradas en el banco superior.",
      "option_a": "Colocar malla electrosoldada mientras se mantiene la producción abajo.",
      "option_b": "Detener la carga en la pata del talud y retirar maquinaria inmediatamente.",
      "option_c": "Rociar agua para compactar el terreno agrietado.",
      "correct_option": 1,
      "feedback": "Cualquier falla geométrica en aceleración exige la detención inmediata del sector para evitar atrapamientos."
    },
    {
      "role": "Supervisor HSEQ",
      "nivel": 5,
      "title": "Sostenimiento Defectuoso en Tubería de Aire",
      "description": "Una línea de aire comprimido a 100 PSI se ha soltado parcialmente de las cadenas de soporte.",
      "option_a": "Sostener manualmente mientras el ayudante ajusta el perno.",
      "option_b": "Despresurizar la línea de inmediato desde la válvula principal antes de reparar.",
      "option_c": "Atar con alambre de amarre provisionalmente sin cortar el aire.",
      "correct_option": 1,
      "feedback": "Trabajar en líneas presurizadas implica riesgo de manguerazo mortal. La despresurización es obligatoria."
    },

    // --- JEFE DE MINAS ---
    {
      "role": "Jefe de Minas",
      "nivel": 1,
      "title": "Plan de Voladura Incompleto",
      "description": "Faltan dos barrenos por cargar con ANFO según el diseño inicial.",
      "option_a": "Completar la carga con cartuchos de dinamita sobrantes.",
      "option_b": "Consultar al diseñador de voladura y reajustar los tiempos de retardo.",
      "option_c": "Disparar la voladura tal como está para cumplir la hora programada.",
      "correct_option": 1,
      "feedback": "Alterar la secuencia de disparos sin validación técnica causa sobrefragmentación o tiros soplados."
    },
    {
      "role": "Jefe de Minas",
      "nivel": 2,
      "title": "Atasco de Chancadora Primaria",
      "description": "Un planchón de roca de sobretamaño obstruye la boca de la chancadora de quijada.",
      "option_a": "Usar la retroexcavadora con picador hidráulico para fragmentarlo.",
      "option_b": "Ingresar al tazón con arnés para colocar una carga hueca manual.",
      "option_c": "Llenar con más mineral para que el peso hunda la roca.",
      "correct_option": 0,
      "feedback": "El uso de martillo hidráulico remoto es la vía segura; el ingreso de personal a chancadoras genera riesgo de atrapamiento."
    },
    {
      "role": "Jefe de Minas",
      "nivel": 3,
      "title": "Inundación en Nivel Inferior",
      "description": "Una falla hidrogeológica libera un flujo de agua no controlado de 50 L/s.",
      "option_a": "Activar las bombas de achique de reserva y reubicar las cuadrillas a niveles superiores.",
      "option_b": "Continuar operando los volquetes hasta que el agua cubra los neumáticos.",
      "option_c": "Sellar la galería con sacos de cemento manualmente.",
      "correct_option": 0,
      "feedback": "La prioridad es el resguardo del personal e incremento del caudal de achique."
    },
    {
      "role": "Jefe de Minas",
      "nivel": 4,
      "title": "Sobreexcavación en Rampa Principal",
      "description": "El avance superó la sección de diseño por 1.5 metros, debilitando los hastiales.",
      "option_a": "Superponer más capas de shotcrete y colocar pernos de anclaje adicionales.",
      "option_b": "Ignorar la sección y continuar el avance planeado.",
      "option_c": "Rellenar la sobreexcavación con desmonte suelto.",
      "correct_option": 0,
      "feedback": "Las secciones sobredimensionadas requieren refuerzo inmediato con empernado y shotcrete estructural."
    },
    {
      "role": "Jefe de Minas",
      "nivel": 5,
      "title": "Tiro Quedado en la Frente",
      "description": "Tras la detonación, se detecta un barreno con explosivo sin detonar en el hastial derecho.",
      "option_a": "Intentar extraer el explosivo tirando del cordón detonante.",
      "option_b": "Lavar el barreno con agua y recargar según el procedimiento de tiros fallidos.",
      "option_c": "Perforar a 5 cm del tiro quedado para detonarlo por simpatía.",
      "correct_option": 1,
      "feedback": "La remoción de tiros quedados mediante lavado controlado evita fricción o detonaciones accidentales."
    },

    // --- GEÓLOGO DE MINA ---
    {
      "role": "Geólogo de Mina",
      "nivel": 1,
      "title": "Caída de Ley en Mapeo de Frente",
      "description": "Las muestras de canal muestran una reducción del 40% en la ley de oro esperada.",
      "option_a": "Mezclar el mineral con stock de alta ley sin notificar.",
      "option_b": "Mapear nuevamente el frente, verificar el contacto estructural y redefinir el límite de minado.",
      "option_c": "Aumentar el ancho de minado para compensar la ley.",
      "correct_option": 1,
      "feedback": "El control de dilución requiere verificar contactos geológicos antes de continuar la extracción."
    },
    {
      "role": "Geólogo de Mina",
      "nivel": 2,
      "title": "Presencia de Roca Arcillosa e Inestable",
      "description": "El frente ingresó a una zona de falla con presencia de panizo altamente alterado.",
      "option_a": "Recomendar sostenimiento pesado con arcos de acero y shotcrete inmediato.",
      "option_b": "Autorizar la perforación normal de voladura.",
      "option_c": "Esperar a que el agua de la falla se seque por sí sola.",
      "correct_option": 0,
      "feedback": "El panizo y las zonas de falla requieren sostenimiento pasivo/activo pesado previo al avance."
    },
    {
      "role": "Geólogo de Mina",
      "nivel": 3,
      "title": "Presencia de Agua Ácida en Testigos de Perforación",
      "description": "El agua de retorno de la perforación diamantina muestra un pH de 3.5.",
      "option_a": "Descargar el agua directamente a la cuneta subterránea.",
      "option_b": "Canalizar el efluente hacia la planta de tratamiento de aguas ácidas.",
      "option_c": "Diluir el agua con agua limpia de la red sin neutralizar.",
      "correct_option": 1,
      "feedback": "El drenaje ácido debe ser neutralizado químicamente en planta de tratamiento para cumplir regulaciones ambientales."
    },
    {
      "role": "Geólogo de Mina",
      "nivel": 4,
      "title": "Discrepancia en Modelo de Bloques",
      "description": "La reconciliación mensual muestra un 20% más de tonelaje pero menor ley que el modelo.",
      "option_a": "Ajustar el variograma y recalibrar la estimación por Kriging en ese dominio.",
      "option_b": "Cambiar los datos de laboratorio manualmente.",
      "option_c": "Ignorar la diferencia por considerarla dentro del margen normal.",
      "correct_option": 0,
      "feedback": "Las desviaciones en la reconciliación exigen la recalibración de parámetros geoestadísticos."
    },
    {
      "role": "Geólogo de Mina",
      "nivel": 5,
      "title": "Colapso de Muestras en Testigoteca",
      "description": "Se perdieron las etiquetas de marcación de 50 metros de testigo diamantino.",
      "option_a": "Adivinar la profundidad basándose en el color de la roca.",
      "option_b": "Remuestrear y realizar correlación litológica con los registros de perforación adyacentes.",
      "option_c": "Descartar los testigos y marcarlos como pérdida geológica.",
      "correct_option": 1,
      "feedback": "La trazabilidad de los datos de perforación requiere validación cruzada antes de ingresar al modelo."
    },

    // --- INGENIERO DE PLANTA ---
    {
      "role": "Ingeniero de Planta",
      "nivel": 1,
      "title": "Sobrecarga en Molino SAG",
      "description": "La presión del sistema hidrostático del molino se incrementa peligrosamente.",
      "option_a": "Aumentar el flujo de agua al molino y reducir temporalmente la alimentación de mineral.",
      "option_b": "Aumentar la carga de bolas de acero inmediatamente.",
      "option_c": "Apagar los ventiladores de refrigeración del motor.",
      "correct_option": 0,
      "feedback": "Disminuir la alimentación y regular la densidad de pulpa evita el embozamiento destructivo del molino."
    },
    {
      "role": "Ingeniero de Planta",
      "nivel": 2,
      "title": "Fuga de Espumante en Flotación",
      "description": "Una manguera de dosificación de reactivo se rompe cerca de las celdas mecánicas.",
      "option_a": "Cerrar la válvula de paso, utilizar EPP para reactivos y reparar la tubería.",
      "option_b": "Dejar que se consuma el reactivo en el recipiente.",
      "option_c": "Lavar la fuga con abundante agua caliente directamente al piso.",
      "correct_option": 0,
      "feedback": "La contención de reactivos químicos con el EPP adecuado previene intoxicaciones o quemaduras químicas."
    },
    {
      "role": "Ingeniero de Planta",
      "nivel": 3,
      "title": "Atasco en Espesador de Relaves",
      "description": "El torque del rastrillo del espesador supera el 85% de la capacidad crítica.",
      "option_a": "Aumentar la descarga de la bomba de underflow y subir la rastra.",
      "option_b": "Apagar la bomba de underflow.",
      "option_c": "Adicionar más floculante para acelerar la sedimentación.",
      "correct_option": 0,
      "feedback": "Elevar la rastra y bombear el sedimento alivia el torque, evitando el colapso mecánico del mecanismo."
    },
    {
      "role": "Ingeniero de Planta",
      "nivel": 4,
      "title": "Desgaste de Revestimiento en Bomba de Pulpa",
      "description": "Se detecta vibración severa y ruido de cavitación en la bomba principal de relaves.",
      "option_a": "Cambiar el flujo a la bomba stand-by y realizar el cambio de liners.",
      "option_b": "Subir las revoluciones de la bomba para eliminar la vibración.",
      "option_c": "Apretar los pernos del chasis sin detener el equipo.",
      "correct_option": 0,
      "feedback": "El uso de la línea de reserva (stand-by) permite intervenir la bomba fallida sin paralizar el proceso."
    },
    {
      "role": "Ingeniero de Planta",
      "nivel": 5,
      "title": "Alta Turbidez en Agua de Recirculación",
      "description": "El clarificado devuelto a la planta contiene alto nivel de sólidos en suspensión (>500 ppm).",
      "option_a": "Ajustar la dosificación del coagulante/floculante y revisar el nivel de cama en el espesador.",
      "option_b": "Abrir la descarga directa al río más cercano.",
      "option_c": "Reducir la presión del agua de lavado de las mallas.",
      "correct_option": 0,
      "feedback": "Optimizar la química de floculación restaura la claridad del agua reciclada para evitar problemas operacionales."
    },

    // --- ESCENARIOS ADICIONALES ---
    {
      "role": "Supervisor HSEQ",
      "nivel": 1,
      "title": "Uso Incorrecto de Arnés en Altura",
      "description": "Un operador trabaja en la plataforma de la planta a 4 metros sin anclarse al cable de vida.",
      "option_a": "Gritarle desde el suelo para que baje.",
      "option_b": "Detener el trabajo de inmediato, hacer que se ancle y aplicar tarjeta de observación.",
      "option_c": "Esperar a que termine la tarea para llamarle la atención en la reunión.",
      "correct_option": 1,
      "feedback": "El trabajo en altura requiere detención inmediata ante la ausencia de punto de anclaje."
    },
    {
      "role": "Jefe de Minas",
      "nivel": 2,
      "title": "Falla del Sistema de Ventilación Principal",
      "description": "El ventilador principal de la mina subterránea se apaga por falla eléctrica externa.",
      "option_a": "Hacer que el personal continúe trabajando con las luces del casco.",
      "option_b": "Ordenar el repliegue de todo el personal hacia las zonas de refugio o superficie.",
      "option_c": "Encender los motores diésel de los volquetes para generar corriente de aire.",
      "correct_option": 1,
      "feedback": "Sin ventilación principal, los gases nocivos se acumulan rápidamente, haciendo obligatoria la retirada."
    },
    {
      "role": "Geólogo de Mina",
      "nivel": 1,
      "title": "Presencia de Agua subterránea inesperada",
      "description": "Al realizar un taladro de exploración se intercepta un acuífero colgado.",
      "option_a": "Colocar un tapón hermético de prueba y medir la presión de agua.",
      "option_b": "Dejar fluir el agua sin control.",
      "option_c": "Sellar el taladro con madera suelta.",
      "correct_option": 0,
      "feedback": "Monitorear la presión de agua es vital para evitar estallidos hidráulicos en las labores subterráneas."
    },
    {
      "role": "Ingeniero de Planta",
      "nivel": 1,
      "title": "Rotura de Malla en Zaranda Vibratoria",
      "description": "Pasan rocas de sobretamaño al circuito secundario de chancado.",
      "option_a": "Parar la zaranda, aislar el circuito y cambiar la malla dañada.",
      "option_b": "Bajar la velocidad de la faja alimentadora sin detener la zaranda.",
      "option_c": "Empujar las rocas con un barretón mientras opera.",
      "correct_option": 0,
      "feedback": "Intervenir zarandas en movimiento genera alto riesgo de atrapamiento; debe aislarse antes de reparar."
    },
    {
      "role": "Jefe de Minas",
      "nivel": 5,
      "title": "Desprendimiento de Roca en Vía de Transito",
      "description": "Cae un bloque de roca de 2 toneladas tapando la mitad de la Rampa A.",
      "option_a": "Desviar el tránsito, colocar vigías, desatar el techo adyacente y retirar el bloque.",
      "option_b": "Pasar rápidamente con los volquetes bordeando el bloque.",
      "option_c": "Empujar el bloque con la camioneta de supervisión.",
      "correct_option": 0,
      "feedback": "La zona debe asegurarse y desatarse mecánicamente antes de retirar el material para prevenir nuevos colapsos."
    }
  ];
}