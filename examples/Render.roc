import cli.Cmd
import cli.OsStr
import cli.Path
import cli.Stderr
import cli.Stdout

Render := [].{

	## Write Pandoc JSON, render standalone HTML, and open it with the
	## operating system's available file-opening command.
	html_and_open! : Str, Str, Bool => Try({}, _)
	html_and_open! = |stem, json, open| {
		if !Cmd.check_available!("pandoc") {
			Stderr.line!("Could not find pandoc on PATH. Install Pandoc and try again.")?
			return Err(Exit(1))
		}

		json_path : Path
		json_path = "${stem}.json"
		html_path = "${stem}.html"
		html_os = OsStr.from_str(html_path)
		json_path.write_utf8!(json)?
		Cmd.call!("pandoc", ["--from=json", "--to=html", "--standalone", "--output=${html_path}", "${stem}.json"])?
		Stdout.line!("Generated ${html_path}")?

		if !open {
			Ok({})
		} else if Cmd.check_available!("xdg-open") {
			Cmd.call!("xdg-open", [html_os])
		} else if Cmd.check_available!("open") {
			Cmd.call!("open", [html_os])
		} else if Cmd.check_available!("cmd") {
			Cmd.call!("cmd", ["/c", "start", "", html_os])
		} else {
			Stderr.line!("Generated ${html_path}, but could not find a command to open it.")?
			Ok({})
		}
	}
}
