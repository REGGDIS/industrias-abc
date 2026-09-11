export type DataMode = 'mock' | 'api';

const rawDataMode = import.meta.env.VITE_DATA_MODE ?? 'mock';

if (rawDataMode !== 'mock' && rawDataMode !== 'api') {
  throw new Error(
    `VITE_DATA_MODE inválido: "${rawDataMode}". Use "mock" o "api".`,
  );
}

export const runtimeConfig = Object.freeze({
  dataMode: rawDataMode as DataMode,
  apiUrl: import.meta.env.VITE_API_URL ?? 'http://localhost:8000/api',
});
