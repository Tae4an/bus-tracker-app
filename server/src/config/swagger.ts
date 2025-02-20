import swaggerJsdoc from 'swagger-jsdoc';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: '셔틀버스 위치 추적 API',
      version: '1.0.0',
      description: '실시간 셔틀버스 추적 시스템을 위한 REST API 및 Socket.IO 이벤트',
      contact: {
        name: '개발팀',
        email: 'dev@example.com'
      },
      license: {
        name: 'MIT',
        url: 'https://opensource.org/licenses/MIT'
      }
    },
    servers: [
      {
        url: 'http://localhost:8080',
        description: '개발 서버'
      },
      {
        url: 'https://api.example.com',
        description: '운영 서버 (예시)'
      }
    ],
    tags: [
      { name: 'Auth', description: '인증 관련 API' },
      { name: 'Buses', description: '버스 관리 및 조회 API' },
      { name: 'Routes', description: '노선 관리 및 조회 API' },
      { name: 'Stops', description: '정류장 관리 및 조회 API' },
      { name: 'Users', description: '사용자 관리 API' },
      { name: 'Realtime', description: '실시간 통신 이벤트 (Socket.IO)' }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: '인증이 필요한 API에 JWT 토큰을 헤더에 포함하세요'
        }
      },
      schemas: {
        // 에러 응답 스키마
        Error: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: false },
            error: { type: 'string', example: '오류 메시지' }
          }
        },
        
        // 인증 관련 스키마
        RegisterRequest: {
          type: 'object',
          required: ['name', 'email', 'password'],
          properties: {
            name: { type: 'string', example: '홍길동' },
            email: { type: 'string', format: 'email', example: 'user@example.com' },
            password: { type: 'string', format: 'password', example: 'password123' },
            role: { type: 'string', enum: ['PASSENGER', 'DRIVER', 'ADMIN'], example: 'PASSENGER' }
          }
        },
        LoginRequest: {
          type: 'object',
          required: ['email', 'password'],
          properties: {
            email: { type: 'string', format: 'email', example: 'user@example.com' },
            password: { type: 'string', format: 'password', example: 'password123' }
          }
        },
        AuthResponse: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: true },
            token: { type: 'string', example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' },
            user: {
              type: 'object',
              properties: {
                id: { type: 'string', example: '60d21b4667d0d8992e610c85' },
                name: { type: 'string', example: '홍길동' },
                email: { type: 'string', example: 'user@example.com' },
                role: { type: 'string', example: 'PASSENGER' }
              }
            }
          }
        },
        
        // 버스 관련 스키마
        Location: {
          type: 'object',
          properties: {
            type: { type: 'string', example: 'Point' },
            coordinates: { 
              type: 'array',
              items: { type: 'number' },
              example: [127.0216, 37.4965]
            }
          }
        },
        Bus: {
          type: 'object',
          properties: {
            id: { type: 'string', example: '60d21b4667d0d8992e610c85' },
            routeId: { type: 'string', example: '60d21b4667d0d8992e610c86' },
            driverId: { type: 'string', example: '60d21b4667d0d8992e610c87', nullable: true },
            status: {
              type: 'string',
              enum: ['ACTIVE', 'IDLE', 'MAINTENANCE', 'OUT_OF_SERVICE'],
              example: 'ACTIVE'
            },
            capacity: { type: 'integer', example: 30 },
            plateNumber: { type: 'string', example: '서울 12가 3456' },
            lastLocation: { $ref: '#/components/schemas/Location' },
            lastUpdated: { type: 'string', format: 'date-time' },
            displayName: { type: 'string', example: 'A-1호차', nullable: true },
            description: { type: 'string', nullable: true },
            createdAt: { type: 'string', format: 'date-time' },
            updatedAt: { type: 'string', format: 'date-time' }
          }
        },
        BusRequest: {
          type: 'object',
          required: ['routeId', 'capacity', 'plateNumber'],
          properties: {
            routeId: { type: 'string', example: '60d21b4667d0d8992e610c86' },
            driverId: { type: 'string', example: '60d21b4667d0d8992e610c87', nullable: true },
            status: {
              type: 'string',
              enum: ['ACTIVE', 'IDLE', 'MAINTENANCE', 'OUT_OF_SERVICE'],
              default: 'IDLE'
            },
            capacity: { type: 'integer', example: 30, minimum: 1 },
            plateNumber: { type: 'string', example: '서울 12가 3456' },
            displayName: { type: 'string', example: 'A-1호차', nullable: true },
            description: { type: 'string', nullable: true }
          }
        },
        
        // 노선 관련 스키마
        ScheduleTime: {
          type: 'object',
          properties: {
            minutes: { type: 'integer', example: 510 } // 8:30 AM
          }
        },
        ScheduleEntry: {
          type: 'object',
          properties: {
            stopId: { type: 'string', example: '60d21b4667d0d8992e610c88' },
            arrivalTime: { $ref: '#/components/schemas/ScheduleTime' },
            departureTime: { $ref: '#/components/schemas/ScheduleTime', nullable: true },
            isTimingPoint: { type: 'boolean', default: false }
          }
        },
        RouteSchedule: {
          type: 'object',
          properties: {
            dayType: {
              type: 'string',
              enum: ['WEEKDAY', 'SATURDAY', 'SUNDAY', 'HOLIDAY'],
              example: 'WEEKDAY'
            },
            entries: {
              type: 'array',
              items: { $ref: '#/components/schemas/ScheduleEntry' }
            }
          }
        },
        Route: {
          type: 'object',
          properties: {
            id: { type: 'string', example: '60d21b4667d0d8992e610c86' },
            name: { type: 'string', example: 'A노선 (순환)' },
            description: { type: 'string', example: '캠퍼스 주요 시설을 순환하는 노선', nullable: true },
            stops: {
              type: 'array',
              items: { type: 'string' },
              example: ['60d21b4667d0d8992e610c88', '60d21b4667d0d8992e610c89']
            },
            schedules: {
              type: 'array',
              items: { $ref: '#/components/schemas/RouteSchedule' },
              nullable: true
            },
            active: { type: 'boolean', default: true },
            color: { type: 'string', example: '#4285F4', nullable: true },
            fareAmount: { type: 'number', example: 1200, nullable: true },
            fareType: { type: 'string', example: '정액제', nullable: true },
            createdAt: { type: 'string', format: 'date-time' },
            updatedAt: { type: 'string', format: 'date-time' }
          }
        },
        
        // 정류장 관련 스키마
        Facilities: {
          type: 'object',
          properties: {
            hasShelter: { type: 'boolean', default: false },
            hasBench: { type: 'boolean', default: false },
            hasLighting: { type: 'boolean', default: false },
            hasElectronicDisplay: { type: 'boolean', default: false },
            isAccessible: { type: 'boolean', default: false }
          }
        },
        Stop: {
          type: 'object',
          properties: {
            id: { type: 'string', example: '60d21b4667d0d8992e610c88' },
            name: { type: 'string', example: '대학 정문' },
            location: { $ref: '#/components/schemas/Location' },
            routes: {
              type: 'array',
              items: { type: 'string' },
              example: ['60d21b4667d0d8992e610c86']
            },
            facilities: { $ref: '#/components/schemas/Facilities' },
            description: { type: 'string', nullable: true },
            address: { type: 'string', example: '서울특별시 강남구 대학로 123', nullable: true },
            imageUrl: { type: 'string', nullable: true },
            createdAt: { type: 'string', format: 'date-time' },
            updatedAt: { type: 'string', format: 'date-time' }
          }
        },
        
        // 사용자 관련 스키마
        User: {
          type: 'object',
          properties: {
            id: { type: 'string', example: '60d21b4667d0d8992e610c87' },
            name: { type: 'string', example: '홍길동' },
            email: { type: 'string', format: 'email', example: 'user@example.com' },
            role: {
              type: 'string',
              enum: ['PASSENGER', 'DRIVER', 'ADMIN'],
              example: 'PASSENGER'
            },
            favoriteRoutes: {
              type: 'array',
              items: { type: 'string' },
              nullable: true
            },
            favoriteStops: {
              type: 'array',
              items: { type: 'string' },
              nullable: true
            },
            licenseNumber: { type: 'string', example: 'DL12345678', nullable: true },
            phoneNumber: { type: 'string', example: '010-1234-5678', nullable: true },
            profileImageUrl: { type: 'string', nullable: true },
            isActive: { type: 'boolean', default: true },
            createdAt: { type: 'string', format: 'date-time' },
            lastLoginAt: { type: 'string', format: 'date-time', nullable: true }
          }
        }
      },
      responses: {
        // 재사용 가능한 응답 정의
        UnauthorizedError: {
          description: '인증되지 않은 사용자',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/Error'
              },
              example: {
                success: false,
                error: '이 리소스에 접근할 권한이 없습니다'
              }
            }
          }
        },
        ForbiddenError: {
          description: '권한 없음',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/Error'
              },
              example: {
                success: false,
                error: '이 작업을 수행할 권한이 없습니다'
              }
            }
          }
        },
        NotFoundError: {
          description: '리소스를 찾을 수 없음',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/Error'
              },
              example: {
                success: false,
                error: '요청한 리소스를 찾을 수 없습니다'
              }
            }
          }
        },
        ServerError: {
          description: '서버 오류',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/Error'
              },
              example: {
                success: false,
                error: '서버 오류가 발생했습니다'
              }
            }
          }
        }
      }
    },
    security: [
      { bearerAuth: [] }
    ]
  },
  apis: [
    './src/routes/*.ts',
    './src/controllers/*.ts',
    './src/socket/index.ts',
    './src/middleware/auth.middleware.ts'
  ]
};

export const specs = swaggerJsdoc(options);