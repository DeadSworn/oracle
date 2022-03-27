#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
int ObjectTarget = INVALID_ENT_REFERENCE;
int ObjectClient;
int g_VotesPvB[MAXPLAYERS+1];
bool IsAttack = false;
bool IsBotEnable = false;
int iCurrentWeapon;
float m_flNextSecondaryAttack;
float fGameTime;
float fSecondaryTime;
float DefaultAngles[3] = {0.0, 90.0, 0.0};
float fVectorTargetLogic[3];
int DistanceDeflect = 285;
int TargetLogicPlayer;
Handle g_hLogicTimer;
bool pause;
float randomAngle = 90.0;
float vectorAngle[3];
float targetVector[3];
float resultangle;
float fVector[3];
public void OnPluginStart(){
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("teamplay_setup_finished", OnSetupFinished, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
	RegAdminCmd("sm_pvb", PVB_Cmd, ADMFLAG_CONVARS, "");
	RegConsoleCmd("sm_votepvb", VotePvB_Cmd, "", 0);
	ServerCommand("sm_cvar nb_blind 1");
	HookEvent("object_deflected", OnDeflect, EventHookMode_PostNoCopy);
}
public void OnEntityCreated(int entity, const char[] classname){
	if (IsBotEnable && StrEqual(classname, "tf_projectile_rocket", false))
	{
		ObjectTarget = entity;
		DistanceDeflect = 285;
	}
}
public void OnEntityDestroyed(int entity){
	if (IsBotEnable && ObjectTarget == entity)	ObjectTarget = INVALID_ENT_REFERENCE;
}
public void OnGameFrame(){
	if (IsBotEnable)
	{
		IsAttack = false;
		if (ObjectTarget != INVALID_ENT_REFERENCE)
		{
			VectorClientToObject();
			if(IsTargetInSightRange())
			{
				float fAngle[3];
				float tempr[3];
				tempr = targetVector;
				LerpVectors(fVector, tempr, 1.0/GetVectorLength(fVector));
				ScaleVector(tempr, GetRandomFloat(0.99, 1.01))
				GetVectorAngles(tempr, fAngle);
				AngleFix(fAngle);
				TeleportEntity(ObjectClient, NULL_VECTOR, fAngle, NULL_VECTOR);
				IsAttack = true;
				ModRateOfFire(iCurrentWeapon);
			}
			else 
			{
				TeleportEntity(ObjectClient, NULL_VECTOR, DefaultAngles, NULL_VECTOR);
			}
			ClientMove();
		}
	}
}
stock void LerpVectors(float fB[3], float fC[3], float rate)
{
	fC[0] = fC[0] + (fB[0] - fC[0]) * rate;
	fC[1] = fC[1] + (fB[1] - fC[1]) * rate;
	fC[2] = fC[2] + (fB[2] - fC[2]) * rate;
}
stock void VectorClientToObject()
{
	float fClientEyePosition[3];	GetClientEyePosition(ObjectClient, fClientEyePosition);
	float fEntityLocation[3];	GetEntPropVector(ObjectTarget, Prop_Send, "m_vecOrigin", fEntityLocation);
	MakeVectorFromPoints(fEntityLocation, fClientEyePosition, fVector);
}
stock bool IsTargetInSightRange()
{
	if (GetVectorLength(fVector) < 50)	return true;
	if (GetVectorLength(fVector) > DistanceDeflect)	return false;
	if (GetEntProp(ObjectTarget, Prop_Send, "m_iTeamNum") == 2)	return false;
	targetVector = fVector;	ScaleVector(targetVector, -1.0);
	NormalizeVector(targetVector, targetVector);
	resultangle = RadToDeg(ArcCosine(GetVectorDotProduct(targetVector, vectorAngle)));
	if(resultangle <= randomAngle/2)	return true;
	else	return false;
}
public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon){
	if (IsBotEnable && IsAttack && IsFakeClient(iClient))	iButtons |= IN_ATTACK2
	return Plugin_Continue;
}
stock void ModRateOfFire(int iWeapon){
	m_flNextSecondaryAttack = GetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack");
	fGameTime = GetGameTime();
	fSecondaryTime = ((m_flNextSecondaryAttack - fGameTime) - 0.99);
	SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", fSecondaryTime + fGameTime);
}
public Action OnPlayerSpawn(Handle hEvent, char[] strEventName, bool bDontBroadcast){
	if (IsBotEnable)
	{
		int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		if (IsFakeClient(iClient) && !IsClientSourceTV(iClient))
		{
			ObjectClient = iClient;
			SetEntProp(ObjectClient, Prop_Data, "m_takedamage", 1, 1);
			iCurrentWeapon = GetEntPropEnt(ObjectClient, Prop_Send,"m_hActiveWeapon");
			GetClientEyeAngles(iClient, DefaultAngles);
			DistanceDeflect = 285;
			ChangeClientTeam(iClient, 2);
		}
		if (IsValidClient(iClient) && !IsFakeClient(iClient) &&  GetClientTeam(iClient) == 2)
		{
			ChangeClientTeam(iClient, 3);
		}
	}
	else DestroyBot();
}
public void OnClientDisconnect_Post(int client){
	g_VotesPvB[client] = 0;
	if (GetRealClientCount() == 0)	DisableMode();
}
public Action PVB_Cmd(int client, args) {
	if(!IsBotEnable)	EnableMode();
	else	DisableMode();
	return Plugin_Handled;
}
public Action VotePvB_Cmd(int client, args){
	if(g_VotesPvB[client] == 1) {
		PrintToChat(client, "\x073EFF3E[Player vs. Bot]\x07ADD8E6 You have already voted.");
	}
	else {
		if(!IsBotEnable)
			PrintToChatAll("\x073EFF3E[Player vs. Bot] \x0700FFFF%N\x01 wants to enable Player vs Bot. (\x07ADD8E6%d\x01 votes, \x07ADD8E6%d\x01 required)", client, GetPlayersVotedPvB() + 1, GetRealClientCount()/2 + 1);

		else
			PrintToChatAll("\x073EFF3E[Player vs. Bot] \x0700FFFF%N\x01 wants to disable Player vs Bot. (\x07ADD8E6%d\x01 votes, \x07ADD8E6%d\x01 required)", client, GetPlayersVotedPvB() + 1, GetRealClientCount()/2 + 1);
		g_VotesPvB[client] = 1;
	}
	
	if(GetPlayersVotedPvB() == GetRealClientCount()/2 + 1) {
		if(IsBotEnable)	DisableMode();
		else	EnableMode();
		for(int i = 0; i < MaxClients; i++)
			g_VotesPvB[i] = 0;
	}
	return Plugin_Handled;
}
stock int GetRealClientCount(){
	int real_player = 0;
	for (int i = 1; i <= MaxClients; i++)	
		if (IsClientInGame(i) && !IsFakeClient(i) && (GetClientTeam(i) == 2 || GetClientTeam(i) == 3)) real_player++;
	return real_player;
}
stock int GetPlayersVotedPvB(){
	int count = 0;
	for(int i = 0; i < MaxClients; i++)	if(IsValidClient(i) && !IsFakeClient(i) && g_VotesPvB[i] == 1)	count++;
	return count;
}
stock bool IsValidClient(int iClient, bool bAlive = false){
	if (iClient >= 1 && iClient <= MaxClients && IsClientConnected(iClient) && IsClientInGame(iClient) && 
	(bAlive == false || IsPlayerAlive(iClient)))
		return true;
	return false;
}
stock void EnableMode(){
	IsBotEnable = true;
	ObjectTarget = INVALID_ENT_REFERENCE;
	InitBot();
	for(int i = 1; i < MaxClients; i++)	if(IsValidClient(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)	ChangeClientTeam(i, 3);
	PrintToChatAll("\x073EFF3E[Player vs. Bot]\x07ADD8E6 Mode Enable.");
}
stock void DisableMode(){
	IsBotEnable = false;
	ClearTimer();
	ObjectTarget = INVALID_ENT_REFERENCE;
	DestroyBot();
	BalanceTeams();
	PrintToChatAll("\x073EFF3E[Player vs. Bot]\x07ADD8E6 Mode Disable.");
}
stock void BalanceTeams(){
	int RandomPlayer;
	int Successfully = GetTeamClientCount(3)/2;
	while(Successfully != 0) 
	{
		RandomPlayer = GetRandomInt(1, MaxClients);
		if (IsValidClient(RandomPlayer) && GetClientTeam(RandomPlayer) == 3)
		{
			ChangeClientTeam(RandomPlayer, 2);
			Successfully -= 1;
		}
	}
}
stock void InitBot(){	ServerCommand("tf_bot_add 1 Pyro red easy \"Oracle BOT\"");}
stock void DestroyBot(){	ServerCommand("tf_bot_kick all");}
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max){
	RegPluginLibrary("bot");
	CreateNative("GetBotStatus", Native_Get_Status);
	return APLRes_Success;
}
public Native_Get_Status(Handle:plugin,numParams){
	return IsBotEnable;
}
public Action OnDeflect(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	if (IsBotEnable && ObjectTarget != INVALID_ENT_REFERENCE)
	{
		int client = GetEntPropEnt(ObjectTarget, Prop_Send, "m_hOwnerEntity");
		if (client == ObjectClient)
		{
			pause = false;
			AngleSelect();
			randomAngle = GetRandomFloat(90.0, 180.0);
			DefaultAngles[0] += GetRandomFloat(-45.0, 45.0);
			DefaultAngles[1] += GetRandomFloat(-45.0, 45.0);
			if (GetRandomInt(1, 3) == 3)
			{
				DistanceDeflect = 0;
				CreateTimer(5.0, ResetDistance);
			}
			else	DistanceDeflect = GetRandomInt(180, 285);
		}
		else	TargetLogicPlayer = client;
	}
}
public Action ResetDistance(Handle hTimer)
{
	DistanceDeflect = 285;
}
stock void ClientMove()
{
	if(GetVectorLength(fVector) < 300.0)
	{
		fVector[2] = 0.0;	
		ScaleVector(fVector, 4.0);
		TeleportEntity(ObjectClient, NULL_VECTOR, NULL_VECTOR, fVector);
		pause = false;
	}
	else if (pause)
	{
		if (!IsValidClient(TargetLogicPlayer, true))
		{
			TargetLogic();
		}
		else
		{
			AngleSelect();
		}
		if (GetVectorLength(fVectorTargetLogic) > 1450.0)
		{
			fVectorTargetLogic[2] = 0.0;
			ScaleVector(fVectorTargetLogic, -4.0);
			TeleportEntity(ObjectClient, NULL_VECTOR, NULL_VECTOR, fVectorTargetLogic);
		}
	}
}
public Action MovePlayerTimer(Handle hTimer)
{
	pause = true;
}
stock void AngleSelect()
{
	float fClientEyePositionBot[3];	GetClientEyePosition(ObjectClient, fClientEyePositionBot);
	float fClientEyePositionPlayer[3];	GetClientEyePosition(TargetLogicPlayer, fClientEyePositionPlayer);
	MakeVectorFromPoints(fClientEyePositionPlayer, fClientEyePositionBot, fVectorTargetLogic);
	GetVectorAngles(fVectorTargetLogic, DefaultAngles);
	AngleFix(DefaultAngles);
	float fClientEyeAngles[3];	GetClientEyeAngles(ObjectClient, fClientEyeAngles);	fClientEyeAngles[0] = 0.0;
	GetAngleVectors(fClientEyeAngles, vectorAngle, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vectorAngle, vectorAngle);
}
stock void TargetLogic()
{
	TargetLogicPlayer = GetRandomPlayer();
	if (TargetLogicPlayer != -1)
	{
		AngleSelect();
	}
}
stock void AngleFix(float Angle[3])
{
	Angle[0] *= -1.0;
	if(Angle[0] > 270)	Angle[0]-=360;
	if (Angle[0] < -180.0)	Angle[0] += 360.0
	Angle[1] += 180.0;
}
stock int GetRandomPlayer()
{
    new clients[MaxClients+1], clientCount;
    for (new i = 1; i <= MaxClients; i++)
        if(IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
            clients[clientCount++] = i;
    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}
public Action OnSetupFinished(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	if (IsBotEnable)
	{
		for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
		{
			if(GetClientTeam(i) > 1)
				SetEntityHealth(i, 2500);
		}
		TargetLogic();
		g_hLogicTimer = CreateTimer(0.1, MovePlayerTimer, _, TIMER_REPEAT);
	}	
}
public Action OnRoundEnd(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	ClearTimer();
}
stock void ClearTimer()
{
	if (g_hLogicTimer != null)
	{
		KillTimer(g_hLogicTimer);
		g_hLogicTimer = null;
	}
}