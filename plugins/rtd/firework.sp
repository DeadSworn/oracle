/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//*********************************//
//  -  Roll The Dice: Firework  -  //
//*********************************//

#define FIREWORK_EXPLOSION	"weapons/flare_detonator_explode.wav"
#define FIREWORK_PARTICLE	"burningplayer_rainbow_flame"

int		g_iFireworkParticle[MAXPLAYERS+1] = {-1, ...};
float	g_fFirework_Push = 4096.0;

void Firework_Proc(const char[] sSettings){

	g_fFirework_Push = StringToFloat(sSettings);

}

void Firework_Start(){

	PrecacheSound(FIREWORK_EXPLOSION);

}

void Firework_Perk(int client, bool apply){

	if(!apply){
	
		if(g_iFireworkParticle[client] > MaxClients && IsValidEntity(g_iFireworkParticle[client])){
		
			AcceptEntityInput(g_iFireworkParticle[client], "Kill");
			g_iFireworkParticle[client] = -1;
		
		}
	
		return;
	
	}

	float fPush[3];
	fPush[2] = g_fFirework_Push;

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fPush);
	
	if(g_iFireworkParticle[client] < 0)
		g_iFireworkParticle[client] = CreateParticle(client, FIREWORK_PARTICLE);
	
	CreateTimer(0.5, Timer_Firework_Explode, GetClientSerial(client));

}

public Action Timer_Firework_Explode(Handle hTimer, int iSerial){

	int client = GetClientFromSerial(iSerial);

	EmitSoundToAll(FIREWORK_EXPLOSION, client);
	
	int iParticle = g_iFireworkParticle[client];
	if(iParticle > MaxClients && IsValidEntity(iParticle))
		AcceptEntityInput(iParticle, "Kill");
	g_iFireworkParticle[client] = -1;

	FakeClientCommandEx(client, "explode");
	
	return Plugin_Stop;

}