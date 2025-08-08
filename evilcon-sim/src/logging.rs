
//! Logger setup.

use tracing_subscriber::{fmt, EnvFilter, Layer};
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::util::SubscriberInitExt;
use tracing_appender::rolling;
use tracing_appender::non_blocking::WorkerGuard;

use std::io;

pub fn init_logger(min_log_level_for_file: &str) -> WorkerGuard {
  let file_appender = rolling::daily("logs", "app.log");
  let (non_blocking_file, guard) = tracing_appender::non_blocking(file_appender);

  // Stdout layer (INFO and above)
  let stdout_layer = fmt::layer()
    .with_writer(io::stdout)
    .with_ansi(true)
    .with_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info")));

  // File layer (all levels)
  let file_layer = fmt::layer()
    .with_writer(non_blocking_file)
    .with_ansi(false)
    .with_filter(EnvFilter::new(min_log_level_for_file));

  // Compose the subscriber
  tracing_subscriber::registry()
    .with(stdout_layer)
    .with(file_layer)
    .init();

  guard
}
