/**
 * 서버 진입점
 * 
 * HTTP 서버 시작, 오류 처리 및 정상 종료 처리를 담당
 * 환경 변수에서 설정을 로드하고 서버를 초기화
 */
import { server } from './app';
import { logger } from './utils/logger';

// 서버 포트 설정 (환경 변수 또는 기본값 5000)
const PORT = process.env.PORT || 5000;

// HTTP 서버 시작
server.listen(PORT, () => {
  logger.info(`서버가 ${process.env.NODE_ENV} 모드로 ${PORT} 포트에서 실행 중입니다`);
  logger.info(`http://localhost:${PORT} 에서 API에 접근할 수 있습니다`);
});

/**
 * 처리되지 않은 예외 처리
 * 예상치 못한 오류 발생 시 로깅 후 프로세스 종료
 */
process.on('uncaughtException', (err) => {
  logger.error(`처리되지 않은 예외: ${err.message}`);
  logger.error(err.stack);
  process.exit(1);
});

/**
 * 처리되지 않은 Promise 거부 처리
 * 비동기 작업의 오류 처리 누락 시 로깅 후 서버 정상 종료
 */
process.on('unhandledRejection', (reason, promise) => {
  logger.error('처리되지 않은 Promise 거부:', promise);
  logger.error('원인:', reason);
  
  // 서버를 정상적으로 종료한 후 프로세스 종료
  server.close(() => {
    logger.info('서버가 정상적으로 종료되었습니다');
    process.exit(1);
  });
});

/**
 * 프로세스 종료 신호 처리 (SIGTERM, SIGINT)
 * 서버를 정상적으로 종료하고 연결을 정리
 */
const shutdownGracefully = () => {
  logger.info('서버 종료 신호를 받았습니다. 정상 종료를 시작합니다...');
  
  server.close(() => {
    logger.info('모든 연결이 종료되었습니다. 프로세스를 종료합니다.');
    process.exit(0);
  });
  
  // 10초 후에도 종료되지 않으면 강제 종료
  setTimeout(() => {
    logger.error('서버가 10초 내에 정상 종료되지 않았습니다. 강제 종료합니다.');
    process.exit(1);
  }, 10000);
};

// 종료 신호 리스너 등록
process.on('SIGTERM', shutdownGracefully);
process.on('SIGINT', shutdownGracefully);