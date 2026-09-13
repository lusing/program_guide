use std::fs;
use std::io;

fn main() -> io::Result<()> {
    let mut path = std::env::temp_dir();
    path.push("guide_rust_file_io.txt");

    fs::write(&path, "line1\nline2\n")?;
    let content = fs::read_to_string(&path)?;
    let line_count = content.lines().count();
    println!("line_count={}", line_count);

    fs::remove_file(&path)?;
    println!("removed={}", path.display());
    Ok(())
}

