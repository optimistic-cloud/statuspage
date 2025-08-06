let logs_dir = "./logs"
let max_log_entries = 1000
let max_retries = 4
let retry_delay = 5sec
let success_codes = [200 202 301 307]

mkdir $logs_dir | ignore

def is-success-code [code] {
  $success_codes | any { |c| $c == ($code | into int) }
}

def log-result [name result] {
  let log_file = $"($logs_dir)/($name)_report.log"
  let timestamp = (date now | format date "%Y-%m-%d %H:%M")
  $"($timestamp), ($result)\n" | save --raw --append $log_file

  # Trim log file to keep only the most recent entries
  if ($log_file | path exists) {
    let entries = ($log_file | open | lines | length)
    if $entries > $max_log_entries {
      let excess = $entries - $max_log_entries
      $log_file | open | lines | skip $excess | save --force $log_file
    }
  }
}

def check-service [url] {
  try {
    let code = (http get $url --max-time 30sec --full | get status | default 0)
    if (is-success-code $code) { "success" } else { "failure" }
  } catch { 
    "failure"
  }
}

def main [config_file: string] {
  if not ($config_file | path exists) { 
    error make { msg: $"Config file ($config_file) does not exist." }
  }

  open $config_file | each { |row|
      let result = check-service ($row.url)

      log-result ($row.name) $result
  }
}
