declare namespace NodeJS {
  export interface ProcessEnv {
    EVENT_BUS_NAME: string;
    EVENT_SOURCE: string;
    LOG_LEVEL: 'silly' | 'trace' | 'debug' | 'info' | 'warn' | 'error' | 'fatal';
    LOG_TYPE: 'json' | 'pretty' | 'hidden';
    PARAMETER_GITHUB_APP_WEBHOOK_SECRET: string;
  }
}
