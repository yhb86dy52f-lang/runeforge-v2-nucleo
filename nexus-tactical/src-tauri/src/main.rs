use std::process::Command;

#[tauri::command]
fn execute_local_command(command: String) -> Result<String, String> {
    let output = Command::new("powershell.exe")
        .args(&["-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", &command])
        .output();

    match output {
        Ok(out) => {
            let stdout = String::from_utf8_lossy(&out.stdout).to_string();
            let stderr = String::from_utf8_lossy(&out.stderr).to_string();
            if !stderr.trim().is_empty() {
                Ok(format!("[ADVERTENCIA/ERROR]\n{}\n\n[SALIDA]\n{}", stderr, stdout))
            } else {
                Ok(stdout)
            }
        }
        Err(e) => Err(format!("Fallo crítico al invocar PowerShell: {}", e)),
    }
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![execute_local_command])
        .run(tauri::generate_context!())
        .expect("Error al iniciar el núcleo de Tauri");
}
