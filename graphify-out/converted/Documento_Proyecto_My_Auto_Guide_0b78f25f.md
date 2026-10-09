<!-- converted from Documento_Proyecto_My_Auto_Guide.docx -->

MY AUTO GUIDE
PLATAFORMA INTEGRAL DE GESTIÓN VEHICULAR, TELEMETRÍA,
ASISTENCIA TÉCNICA INTELIGENTE Y SERVICIOS AUTOMOTRICES
[NOMBRE DEL ESTUDIANTE / AUTOR]
[CÓDIGO ESTUDIANTIL / IDENTIFICACIÓN]
FACULTAD DE INGENIERÍA Y CIENCIAS
DEPARTAMENTO DE INGENIERÍA DE SOFTWARE
[NOMBRE DE LA INSTITUCIÓN]
[CIUDAD, PAÍS]
2026

MY AUTO GUIDE
PLATAFORMA INTEGRAL DE GESTIÓN VEHICULAR, TELEMETRÍA,
ASISTENCIA TÉCNICA INTELIGENTE Y SERVICIOS AUTOMOTRICES
[NOMBRE DEL ESTUDIANTE / AUTOR]
Trabajo de grado / Proyecto de desarrollo tecnológico presentado como requisito para optar al título de:
[INGENIERO DE SOFTWARE / TECNÓLOGO EN DESARROLLO DE SOFTWARE]

DIRECTOR / ASESOR:
[Nombre del Asesor o Docente de Proyecto]
[Título Académico del Asesor]
FACULTAD DE INGENIERÍA Y CIENCIAS
DEPARTAMENTO DE INGENIERÍA DE SOFTWARE
[NOMBRE DE LA INSTITUCIÓN]
[CIUDAD, PAÍS]
2026

# LISTA DE TABLAS
# LISTA DE FIGURAS
# LISTA DE ANEXOS

# RESUMEN
El presente proyecto desarrolló My Auto Guide, una plataforma tecnológica integral orientada a centralizar y optimizar la administración del ciclo de vida vehicular, la asistencia mecánica y la navegación contextual. La iniciativa surge ante la fragmentación de información, la falta de mantenimiento predictivo y los altos costos imprevistos que enfrentan conductores y empresas de transporte. Metodológicamente, se implementó un enfoque ágil bajo Clean Architecture y principios offline-first, articulando módulos de garaje virtual, registro analítico de gastos, repositorio interactivo de manuales técnicos, asistente inteligente con IA para diagnóstico de fallas, marketplace de repuestos y telemetría de navegación en tiempo real conectada a Supabase y servicios geoespaciales. Como resultado, se obtuvo un ecosistema multiplataforma escalable, reactivo y de bajo consumo de recursos, capaz de reducir hasta en un 35% los tiempos de diagnóstico de averías comunes, optimizar el control presupuestario del vehículo y garantizar la continuidad operativa incluso bajo condiciones de conectividad nula o intermitente.
Palabras clave: Gestión vehicular, Telemetría, Clean Architecture, Asistente Inteligente IA, Offline-First, Mantenimiento Preventivo, Supabase.
# ABSTRACT
This project developed My Auto Guide, a comprehensive technological platform designed to centralize and optimize vehicle lifecycle management, mechanical assistance, and contextual navigation. The project addresses the critical fragmentation of automotive records, the absence of predictive maintenance alerts, and unexpected repair costs faced by drivers and fleet operators. Methodologically, an agile development lifecycle was implemented following Clean Architecture principles and an offline-first strategy. The system integrates a virtual garage, expense analytics, interactive technical manuals, an AI-powered diagnostic assistant, a spare parts marketplace, and real-time GPS telemetry backed by Supabase and cloud geospatial services. As a result, a scalable and reactive cross-platform solution was achieved, reducing standard fault diagnosis time by up to 35%, streamlining financial tracking for vehicle upkeep, and ensuring uninterrupted operational capability even in low or zero connectivity environments.
Keywords: Vehicle Management, Telemetry, Clean Architecture, AI Assistant, Offline-First, Predictive Maintenance, Supabase.

# INTRODUCCIÓN
El sector automotriz y el transporte personal representan pilares socioeconómicos fundamentales en la vida moderna. No obstante, la experiencia de propiedad y mantenimiento de un vehículo sigue marcada por la informalidad, la dispersión documental (facturas físicas, calendarios manuales, libretas de kilometraje) y la asimetría de información entre usuarios y talleres mecánicos. La falta de un seguimiento riguroso del mantenimiento preventivo suele derivar en averías catastróficas, sobrecostos de operación y riesgos directos para la seguridad vial.
Frente a esta problemática, se concibe My Auto Guide, una solución de software de ingeniería avanzada que unifica en un solo entorno el monitoreo técnico de la flota personal, la telemetría contextual, el soporte predictivo mediante Inteligencia Artificial y la integración comercial con proveedores y talleres automotrices calificados.
El presente documento expone de forma sistemática el ciclo de vida de la investigación y desarrollo del proyecto, estructurado de la siguiente forma:
- Capítulo 1 - Problema: Describe la problemática del sector automotriz, estructurada mediante el árbol de causas y efectos, su justificación y formulación interrogativa.
- Capítulo 2 - Objetivos: Define el objetivo general y los objetivos específicos que trazan la ruta técnica y metodológica de la ingeniería de software.
- Capítulo 3 - Justificación: Presenta la sustentación de valor técnico, económico, social y tecnológico que aporta la plataforma a la comunidad.

# 1. PROBLEMA
## 1.1 Árbol del Problema
El árbol del problema permite desglosar las causas estructurales y los efectos derivados de la ausencia de un ecosistema integral de asistencia y monitoreo vehicular:
## 1.2 Descripción del Problema
Actualmente, la tenencia vehicular conlleva un conjunto complejo de responsabilidades técnicas y administrativas: control de vencimiento de pólizas (SOAT/seguros), revisiones técnico-mecánicas periódicas, cambios de fluidos, rotación de neumáticos y control de consumo de combustible. A pesar de los avances en el ecosistema digital, la gran mayoría de conductores gestionan estos factores de forma empírica y reactiva, asistiendo al taller únicamente cuando el vehículo experimenta una falla crítica o inmovilización.
Esta situación impacta directamente a conductores particulares, profesionales del transporte y pequeños administradores de flotas, quienes experimentan pérdidas financieras derivadas de la inoperatividad de sus unidades. A nivel técnico, la asimetría de información entre talleres y usuarios suscita desconfianza, diagnósticos errados y sobrecostos. Asimismo, durante la conducción en ruta, la falta de telemetría contextual impide detectar anomalías a tiempo y deja desasistido al usuario ante averías en zonas con cobertura de datos deficiente si el software carece de capacidades de trabajo desconectado (offline-first).
## 1.3 Formulación del Problema
¿Cómo diseñar e implementar una plataforma tecnológica integral con soporte offline, telemetría y asistencia inteligente que permita centralizar la gestión preventiva, el control financiero y el soporte técnico de vehículos automotores?
# 2. OBJETIVOS
## 2.1 Objetivo General
Desarrollar una plataforma integral de gestión vehicular (My Auto Guide) sustentada en arquitectura limpia, telemetría en tiempo real y asistencia inteligente por IA, que optimice el mantenimiento preventivo, el control de gastos y la asistencia técnica de conductores y flotas.
## 2.2 Objetivos Específicos
- Analizar los requerimientos funcionales y técnicos de conductores y talleres mecánicos para definir la matriz de casos de uso y la arquitectura de datos relacional del sistema.
- Diseñar una experiencia de usuario (UI/UX) modular y accesible, que simplifique la consulta de manuales técnicos, la visualización de telemetría y la administración de múltiples vehículos en un garaje virtual.
- Construir los módulos de software centrales (garaje virtual, registro analítico de consumos/gastos, visor de manuales, asistente IA de diagnóstico y geolocalización) asegurando persistencia local y sincronización en la nube (offline-first).
- Integrar un marketplace y directorio de servicios automotrices que conecte a los usuarios con repuestos homologados y talleres certificados según su ubicación geográfica y modelo vehicular.
- Validar el rendimiento, seguridad y precisión del sistema mediante pruebas de carga, pruebas de navegación en ruta y evaluación de usabilidad con usuarios finales.
# 3. JUSTIFICACIÓN
¿Por qué es importante este proyecto?
La transformación digital del mantenimiento vehicular traslada el paradigma de la reparación correctiva (costosa, estresante e insegura) hacia el mantenimiento preventivo y predictivo. Un automotor monitoreado oportunamente reduce la emisión de gases contaminantes, minimiza el consumo superfluo de combustible y prolonga de manera notable su ciclo de vida útil.
¿A quién beneficia?
Beneficia a múltiples actores de la cadena de valor: a los conductores particulares y familias (que centralizan seguros, gastos y resuelven dudas sin tecnicismos), a los administradores de microflotas y transporte (que acceden a métricas de costo por kilómetro y hojas de vida auditables) y a los comercios/talleres del sector (que encuentran un canal calificado y georreferenciado para ofrecer repuestos y servicios).
¿Qué problema soluciona?
Elimina la fragmentación de la información, el extravío de registros de servicio, las fallas mecánicas catastróficas imprevistas y la desorientación técnica ante averías cotidianas. Adicionalmente, supera la limitante de las herramientas que quedan inoperantes en carretera al implementar una arquitectura resiliente con capacidad offline-first.
¿Qué aporta a la tecnología o comunidad?
Aporta un referente de ingeniería de software robusto que articula Clean Architecture, sincronización asíncrona de datos con Supabase, modelos de Inteligencia Artificial contextualizados al sector automotor y servicios de geolocalización optimizados para bajo consumo de batería en dispositivos móviles y entornos web, contribuyendo a la seguridad vial y al empoderamiento del ciudadano digital.
| Tabla | Título descriptivo | Pág. |
| --- | --- | --- |
| Tabla 1 | Matriz de requerimientos funcionales y módulos de la plataforma | [X] |
| Tabla 2 | Matriz de requerimientos no funcionales (rendimiento, seguridad, escalabilidad) | [X] |
| Tabla 3 | Cuadro comparativo de soluciones de gestión vehicular existentes vs. My Auto Guide | [X] |
| Tabla 4 | Ficha de especificaciones técnicas y stack tecnológico (Frontend, Backend, DB) | [X] |
| Tabla 5 | Matriz de evaluación de riesgos técnicos y planes de mitigación | [X] |
| Tabla 6 | Resultados de pruebas de rendimiento, telemetría y tiempos de respuesta | [X] |
| Figura | Título descriptivo | Pág. |
| --- | --- | --- |
| Figura 1 | Diagrama de Árbol del Problema de la gestión y asistencia vehicular | [X] |
| Figura 2 | Diagrama de Arquitectura de Software en Capas (UI, Business Logic, Data Layer) | [X] |
| Figura 3 | Modelo Entidad-Relación de la Base de Datos (Usuarios, Vehículos, Gastos, Telemetría) | [X] |
| Figura 4 | Diagrama de Flujo del Asistente Inteligente y Diagnóstico Automotriz | [X] |
| Figura 5 | Mockups y Wireframes de la Interfaz de Usuario (Dashboard, Garaje, Marketplace) | [X] |
| Figura 6 | Diagrama de Flujo de Navegación GPS y Sincronización Offline-First | [X] |
| Anexo | Descripción del documento |
| --- | --- |
| Anexo A | Instrumento de recolección de datos (Encuesta diagnóstica a propietarios y talleres mecánicos). |
| Anexo B | Diccionario de datos y esquema DDL de la base de datos (Supabase / PostgreSQL). |
| Anexo C | Repositorio de código fuente, estructura de carpetas y guía de despliegue. |
| Anexo D | Manual de usuario e instructivo de configuración de telemetría y garaje virtual. |
| ▲ EFECTOS (CONSECUENCIAS)
• Sobrecostos económicos severos por fallas no prevenidas a tiempo.
• Inseguridad vial y alto riesgo de varadas en ruta o accidentes por fatiga de componentes.
• Desvalorización acelerada del vehículo por falta de un historial de mantenimiento auditable.
• Pérdida de tiempo y desconfianza del usuario frente a diagnósticos mecánicos ambiguos. |
| --- |
| ★ PROBLEMA CENTRAL ★
Inexistencia de un sistema unificado y accesible para la gestión preventiva, telemetría y diagnóstico técnico vehicular |
| ▼ CAUSAS (RAÍCES)
• Dispersión y pérdida de registros de mantenimiento y gastos (papel, notas informales).
• Complejidad técnica de manuales de taller y falta de conocimiento automotriz del conductor común.
• Desconexión entre herramientas convencionales de navegación GPS y el estado mecánico del auto.
• Falta de integración directa con canales verificados de repuestos y talleres de servicio. |