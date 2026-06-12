# Guía de Desarrollo en Frappe / ERPNext

Esta guía describe el flujo de trabajo estándar para desarrollar y extender funcionalidades en este entorno de **Frappe Bench**, sin comprometer la integridad de la plataforma base (Frappe/ERPNext).

---

## 🚨 Regla de Oro: Crear Aplicaciones Personalizadas (Custom Apps)

**Nunca modifiques directamente los repositorios oficiales de Frappe o ERPNext** (ubicados bajo `apps/frappe` o `apps/erpnext`). Cualquier cambio directo se perderá al actualizar el bench o las aplicaciones mediante Git.

Toda personalización de código, nuevas vistas, tablas o integraciones deben vivir en su propia **Custom App**.

---

## 🛠️ Comandos Esenciales de `bench`

Ejecuta estos comandos desde la raíz del bench (`/home/je_7_/mi-erp-bench` en tu entorno de WSL/Ubuntu):

### 1. Gestión del Servidor de Desarrollo
* **Iniciar servicios**: Corre la base de datos, colas Redis, Socket.io y el servidor web local.
  ```bash
  bench start
  ```
  *(Este comando lee el archivo [Procfile](file://wsl.localhost/Ubuntu/home/je_7_/mi-erp-bench/Procfile) para levantar todos los subprocesos necesarios).*

### 2. Creación e Instalación de Apps
* **Crear una nueva App personalizada**:
  ```bash
  bench new-app <nombre_de_tu_app>
  ```
  *Recomendación: Usa minúsculas y guiones bajos (ej. `mi_modulo_cliente`).*

* **Instalar la App en el sitio web**:
  ```bash
  bench --site erp.local install-app <nombre_de_tu_app>
  ```

### 3. Desarrollo y Consola
* **Activar Modo Desarrollador (Developer Mode)**: Es obligatorio para guardar DocTypes en el sistema de archivos (código) y no solo en la base de datos.
  ```bash
  bench --site erp.local set-config developer_mode 1
  ```
* **Consola de Python Interactiva**: Accede al entorno de Frappe directamente desde la terminal con contexto cargado.
  ```bash
  bench --site erp.local console
  ```
* **Migrar Base de Datos**: Ejecuta migraciones de esquema cuando modifiques archivos JSON de DocTypes manualmente o descargues cambios del repositorio.
  ```bash
  bench --site erp.local migrate
  ```

---

## 📦 Concepto Clave: DocTypes

En Frappe, la base de datos, la interfaz de usuario y la lógica de negocio se definen a través de **DocTypes** (Document Types).

Cuando el **Developer Mode** está activo, crear un DocType desde la interfaz de usuario web generará automáticamente una carpeta física dentro de tu aplicación con la siguiente estructura:

```text
apps/<tu_app>/<tu_app>/<modulo>/doctype/<nombre_del_doctype>/
├── __init__.py
├── <nombre_del_doctype>.json  # Metadatos del esquema, campos, permisos y vistas.
├── <nombre_del_doctype>.py    # Controlador del Servidor (Python) - Lógica de negocio backend.
└── <nombre_del_doctype>.js    # Controlador del Cliente (JavaScript) - Eventos UI frontend.
```

### Eventos en el Servidor (Python)
Dentro del archivo `.py` puedes capturar eventos del ciclo de vida del documento heredando de `Document`:

```python
import frappe
from frappe.model.document import Document

class MiDocType(Document):
    def validate(self):
        """Se ejecuta automáticamente antes de guardar el registro en base de datos."""
        if not self.campo_ejemplo:
            frappe.throw("El campo Ejemplo es obligatorio.")

    def on_submit(self):
        """Se ejecuta al presionar el botón 'Submit' (Confirmar)."""
        pass
```

### Eventos en el Cliente (JavaScript)
Dentro del archivo `.js` manejas interacciones de interfaz de usuario como cambios en campos, botones personalizados, ocultar/mostrar secciones:

```javascript
frappe.ui.form.on('Mi DocType', {
    refresh(frm) {
        // Se ejecuta al cargar o recargar el formulario
        frm.add_custom_button('Generar Reporte', () => {
            frappe.msgprint('Acción ejecutada');
        });
    },
    tipo_de_cliente(frm) {
        // Se ejecuta cuando el campo 'tipo_de_cliente' cambia de valor
        if (frm.doc.tipo_de_cliente === 'Empresa') {
            frm.set_df_property('rfc_nit', 'reqd', 1); // Hace obligatorio el campo rfc_nit
        } else {
            frm.set_df_property('rfc_nit', 'reqd', 0);
        }
    }
});
```

---

## 🔗 Extender Módulos Existentes de ERPNext (Hooks)

Si necesitas alterar el flujo de ERPNext (por ejemplo, validar algo en un *Sales Invoice* original antes de guardar), debes usar el archivo `hooks.py` dentro de tu custom app. 

### Ejemplos comunes de `hooks.py`

1. **Escuchar eventos de base de datos de otros DocTypes**:
   ```python
   doc_events = {
       "Sales Invoice": {
           "validate": "mi_modulo_cliente.api.validar_factura_venta"
       }
   }
   ```
2. **Inyectar JS personalizado en vistas de otros DocTypes**:
   ```python
   doctype_js = {
       "Customer": "public/js/customer_customization.js"
   }
   ```

*(Para una referencia completa de los hooks soportados, puedes revisar el archivo [hooks.md](file://wsl.localhost/Ubuntu/home/je_7_/mi-erp-bench/apps/frappe/hooks.md) en Frappe).*

---

## 🗂️ Estructura del Entorno Local

* **[Procfile](file://wsl.localhost/Ubuntu/home/je_7_/mi-erp-bench/Procfile)**: Define qué procesos arrancar con `bench start`.
* **[sites/common_site_config.json](file://wsl.localhost/Ubuntu/home/je_7_/mi-erp-bench/sites/common_site_config.json)**: Parámetros del puerto web (`8000`), websockets (`9000`), puertos Redis y modo de recarga activa (`live_reload`).
* **[sites/erp.local/site_config.json](file://wsl.localhost/Ubuntu/home/je_7_/mi-erp-bench/sites/erp.local/site_config.json)**: Configuración de la base de datos local asociada al sitio.
