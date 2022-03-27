/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//********************************//
//  -  Roll The Dice: Drugged  -  //
//********************************//

bool	g_bIsDrugged[MAXPLAYERS+1]	= {false, ...};
UserMsg g_DruggedMsgId;
float	g_fDrugged_Interval = 1.0;

void Drugged_Proc(const char[] sSettings){

	g_fDrugged_Interval = StringToFloat(sSettings);

}

void Drugged_Start(){

	g_DruggedMsgId = GetUserMessageId("Fade");

}

void Drugged_Perk(int client, bool apply){

	if(IsFakeClient(client))
		return;

	if(apply)
		Drugged_ApplyPerk(client);

	else
		g_bIsDrugged[client] = false;

}

void Drugged_ApplyPerk(int client){

	CreateTimer(g_fDrugged_Interval, Timer_DrugTick, GetClientSerial(client), TIMER_REPEAT);
	g_bIsDrugged[client] = true;

}

public Action Timer_DrugTick(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);

	if(!IsValidClient(client))
		return Plugin_Stop;

	if(!g_bIsDrugged[client]){
	
		Drugged_RemovePerk(client);
		return Plugin_Stop;
	
	}

	Drugged_Tick(client);
	return Plugin_Continue;

}

void Drugged_Tick(int client){

	float fPunch[3];
	fPunch[0] = GetRandomFloat(-45.0, 45.0);
	fPunch[1] = GetRandomFloat(-45.0, 45.0);
	fPunch[2] = GetRandomFloat(-45.0, 45.0);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fPunch);

	int iClients[2];
	iClients[0] = client;

	Handle hMsg = StartMessageEx(g_DruggedMsgId, iClients, 1);
	BfWriteShort(hMsg, 255);
	BfWriteShort(hMsg, 255);
	BfWriteShort(hMsg, (0x0002));
	BfWriteByte(hMsg, GetRandomInt(0,255));
	BfWriteByte(hMsg, GetRandomInt(0,255));
	BfWriteByte(hMsg, GetRandomInt(0,255));
	BfWriteByte(hMsg, 128);

	EndMessage();

}

void Drugged_RemovePerk(int client){

	float fAng[3]; GetClientEyeAngles(client, fAng);
	fAng[2] = 0.0;

	TeleportEntity(client, NULL_VECTOR, fAng, NULL_VECTOR);

	int iClients[2];
	iClients[0] = client;

	Handle hMsg = StartMessageEx(g_DruggedMsgId, iClients, 1);

	BfWriteShort(hMsg, 1536);
	BfWriteShort(hMsg, 1536);
	BfWriteShort(hMsg, (0x0001 | 0x0010));
	BfWriteByte(hMsg, 0);
	BfWriteByte(hMsg, 0);
	BfWriteByte(hMsg, 0);
	BfWriteByte(hMsg, 0);

	EndMessage();

}