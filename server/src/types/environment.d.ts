/**
 * 환경 변수 타입 정의
 * 
 * TypeScript에서 process.env 객체의 타입 안전성을 보장하기 위한 정의
 * 이 파일은 컴파일 과정에서만 사용되며 런타임에는 영향을 주지 않음
 */
declare global {
    namespace NodeJS {
      interface ProcessEnv {
        // 필수 환경 변수
        NODE_ENV: 'development' | 'production' | 'test';
        PORT: string;
        MONGODB_URI: string;
        JWT_SECRET: string;
        
        // 선택적 환경 변수
        JWT_EXPIRE?: string;
        JWT_COOKIE_EXPIRE?: string;
        CLIENT_URL?: string;
        REDIS_URL?: string;
        LOG_LEVEL?: 'error' | 'warn' | 'info' | 'debug';
      }
    }
  }
  
  // 이 파일이 모듈로 인식되도록 빈 export 추가
  export {};