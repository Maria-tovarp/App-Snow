# Academic Planner

Aplicación móvil desarrollada en Flutter para la organización académica del estudiante. Permite gestionar materias, tareas, metas, proyectos, sesiones de estudio Pomodoro y calendario.

## Estructura del proyecto

```text
lib/
  app/                      # Configuración global de app, rutas y tema
  core/
    services/               # Servicios compartidos (ej. carga de JSON local)
  features/
    auth/
      data/
      presentation/
    home/
      presentation/
    materias/
      data/
      presentation/
    tareas/
      data/
      presentation/
    metas/
      data/
      presentation/
    proyectos/
      data/
      presentation/
    pomodoro/
      data/
      presentation/
    calendario/
      presentation/
    profile/
      presentation/
assets/
  data/                     # Archivos JSON de apoyo / seed local
  sounds/                   # Recursos multimedia
```

## Cómo cumple con la rúbrica

### 1. UI
- Se usa Material 3 con tema unificado.
- Hay formularios, cards, listas, diálogos, indicadores de carga y navegación por rutas.
- La interfaz mantiene colores, bordes y estilos consistentes.

### 2. UX
- Navegación con `go_router`.
- Mensajes al usuario con `SnackBar` para errores y confirmaciones.
- Indicadores de carga con `CircularProgressIndicator`.

### 3. Estructura del proyecto
- Separación clara por módulos (`features`).
- División por capas: `data`, `presentation` y configuración general en `app` / `core`.

### 4. Manejo de datos (JSON y listas)
- Se usan modelos con `fromJson()` y `toJson()`.
- Se usan listas dinámicas en Dart (`List<T>`), equivalentes al manejo de colecciones tipo ArrayList en otros lenguajes.
- Se integraron archivos JSON locales en `assets/data/` como respaldo y evidencia del criterio de JSON.
- No se usa base de datos ni backend: los datos se cargan desde JSON local y se manipulan con listas en memoria durante la ejecución.

### 5. Sustentación
Para explicar la app en la exposición, revisar el archivo `SUSTENTACION_PARCIAL.md`.

## Ejecución

1. Verificar que los archivos JSON estén en `assets/data/`.
2. Instalar dependencias:
   ```bash
   flutter pub get
   ```
3. Ejecutar la aplicación:
   ```bash
   flutter run
   ```


## Nota importante
Este proyecto fue ajustado para el parcial sin uso de base de datos. Los datos se manejan con archivos JSON locales y listas en memoria, en coherencia con la rúbrica.
