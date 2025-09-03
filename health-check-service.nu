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

def hc-ping [name, result] {
  if ($env.HC_PING_KEY? | is-not-empty) {
    try {
      if ($result == "success") { 
        http get $"https://hc-ping.com/($env.HC_PING_KEY)/($name)-status?create=1" --max-time 30sec | ignore
        print $"✓ Pinged healthchecks.io: ($name) -> success"
      } else { 
        http get $"https://hc-ping.com/($env.HC_PING_KEY)/($name)-status/fail?create=1" --max-time 30sec | ignore
        print $"✓ Pinged healthchecks.io: ($name) -> failure"
      }
    } catch {
      print $"✗ Failed to ping healthchecks.io for ($name)"
    }
  } else {
    print "HC_PING_KEY secret not found - skipping healthchecks.io ping"
  }
}

def main [--name: string --url: string] {
  let result = check-service $url

  hc-ping $name $result
  log-result $name $result
}
