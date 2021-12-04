#ifndef _STRUCT_IMPORT_H
#define _STRUCT_IMPORT_H

/******************************************************************************/
/* GENERAL */
/******************************************************************************/

#define MAXPERCEPTIONOBJNUM 20
#define POLYGONMAXLINE 4

typedef struct {
  unsigned int LineType;
  float A;
  float B;
  float C;
} Line_t;


typedef struct {
	unsigned int len;
	unsigned char state;
	unsigned char mode;
	unsigned short error_code;
	unsigned long long time_stamp;
} Header_t;


typedef struct {
	float x;
	float y;
} point_t;


typedef struct {
	point_t pt;
	float heading;
} pose_t;

/******************************************************************************/
/* PP */
/******************************************************************************/
typedef struct {
	unsigned char type;
	unsigned char CtrlType;
	int dir;
	float steerAngle;
	float radius;
	float Len;
	point_t circleCenter;
	pose_t keyPoint;
} PathSeg_t;


typedef struct {
	Header_t header;
	unsigned char segNum;
	unsigned char curIndex;
	int PathId;
	PathSeg_t pathSeg[10];
	pose_t SlotEndPose;
	unsigned char IsSameDir2End;
	unsigned char DisableSwitchRecal;
} Path_t;

/******************************************************************************/
/* SLOT */
/******************************************************************************/
typedef struct {
	Header_t header;
	unsigned int x_y_type[450];
	unsigned short objNum;
} ObjectInfo_t;

typedef struct {
	ObjectInfo_t boundaryData;
	int LeftObjNum;
	int RightObjNum;
	int FrontObjNum;
	int RearObjNum;
	point_t LeftObjs[MAXPERCEPTIONOBJNUM];
	point_t RightObjs[MAXPERCEPTIONOBJNUM];
	point_t FrontObjs[MAXPERCEPTIONOBJNUM];
	point_t RearObjs[MAXPERCEPTIONOBJNUM];
    point_t objLeft;
	point_t objRight;
} ObstacleInfo_t;

typedef struct {
  unsigned char objFrontState;
  unsigned char objRearState;
  unsigned char objLeftState;
  unsigned char objRightState;
  point_t ObjFront;
  point_t ObjRear;
  point_t ObjLeft;
  point_t ObjRight;
} Scene_t;

typedef struct {
  Header_t header;
  unsigned char slotType;
  //unsigned char sceneType :7;
  unsigned char sceneType7IsRightSlot1;
  Scene_t sceneInfo;
  pose_t SlotEndPose;
  pose_t SlotBasePose;
  float EndOffY;
  Line_t EndPosLine;
  Path_t parkoutPath;
} Slot_t;

/******************************************************************************/
/* MEB */
/******************************************************************************/
typedef struct {
  Header_t header;
  float safeVel;
  float safeDistance;
  pose_t stopPose;
  point_t objPos;
} MebData_t;

/******************************************************************************/
/* PF */
/******************************************************************************/
typedef struct {
  int IsEnable;
  int VCState;
  float Speed;
  float SteerAngle;
  float Distance;
  float Acc;
  int IsAEB;
  int Shift;
} VehicleCtrl_t;


typedef struct {
  int PathId;
  float CarFollowErr;
  int CurPathIndex;
  pose_t curPose;
  pose_t transform;
  float PulseSpd;
  float SteerWheelAngle;
  float radius;
  int ShiftState;
  int Dir;
  int PreShiftState;
} CarState_t;


typedef struct {
  Header_t header;
  VehicleCtrl_t vcData;
  CarState_t carState;
} PFData_t;

/******************************************************************************/
/* ODO */
/******************************************************************************/
typedef struct {
  pose_t sCurPose;
  pose_t sDetPose;
  float fTurnR;
  float fFwdDist;
  float mileage;
} OdometryData_t;


typedef struct {
  unsigned int obj[40];	
} UssObjs_t;


typedef struct {
  pose_t slotbase;
  float xLen;	
  float yLen;
} Slot;


typedef struct {
	Slot slot[4];
} UssSlot_t;


typedef struct {
  int ShiftState;
  int Dir;
  float SteerWheelAngle;
  float radius;
  float Speed;
  float PulseSpd;
  unsigned short FLWhlDistPlsCntr;
  unsigned short FRWhlDistPlsCntr;
  unsigned short RLWhlDistPlsCntr;
  unsigned short RRWhlDistPlsCntr;
  unsigned char IsBrakePedalPress;
  unsigned char eps_status;
  unsigned char door_status;
  unsigned char safebelt_status;
  unsigned char rearmirror_status;
} VehicleSourceData_t;


typedef struct {
	Header_t header;
	OdometryData_t odoData;
	UssObjs_t ussObjs;
	UssSlot_t ussSlot;
	VehicleSourceData_t vehicleSrcData;
} VehicleData_t;


/******************************************************************************/
/* Polygon */
/******************************************************************************/
typedef struct {
	int ptNum;
	pose_t basePt;
	point_t pt[POLYGONMAXLINE];
	float angle;
} Polygon_t;



#endif