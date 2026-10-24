use tauri::{Manager, RunEvent};
use tauri_plugin_shell::ShellExt;
use std::sync::Mutex;

struct BackendProcess(Mutex<Option<tauri_plugin_shell::process::CommandChild>>);

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let app = tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .setup(|app| {
            // Lanzar el sidecar de Python
            let sidecar_command = app.shell().sidecar("runeforge_backend").unwrap();
            let (mut rx, child) = sidecar_command.spawn().expect("Failed to spawn sidecar");
            
            app.manage(BackendProcess(Mutex::new(Some(child))));

            // Escuchar la salida de Python en consola (para debug)
            tauri::async_runtime::spawn(async move {
                while let Some(event) = rx.recv().await {
                    if let tauri_plugin_shell::process::CommandEvent::Stdout(line) = event {
                        println!("[Python]: {}", String::from_utf8_lossy(&line));
                    }
                }
            });

            Ok(())
        })
        .build(tauri::generate_context!())
        .expect("error while building tauri application");

    // Manejar el cierre de la app para matar el proceso de Python
    app.run(|app_handle, event| {
        if let RunEvent::ExitRequested { .. } = event {
            if let Some(process) = app_handle.try_state::<BackendProcess>() {
                if let Some(child) = process.0.lock().unwrap().take() {
                    let _ = child.kill();
                }
            }
        }
    });
}
