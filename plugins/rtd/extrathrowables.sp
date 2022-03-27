/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//*****************************************//
//  -  Roll The Dice: Extra Throwables  -  //
//*****************************************//

int g_iExtraThrowables_Amount = 20;

void ExtraThrowables_Proc(const char[] sSettings){

	g_iExtraThrowables_Amount = StringToInt(sSettings);

}

void ExtraThrowables_Perk(int client){

	int iWeapon = 0;

	if(TF2_GetPlayerClass(client) == TFClass_Scout){
	
		iWeapon = GetPlayerWeaponSlot(client, 2);
		
		if(IsValidEntity(iWeapon)){
		
			int iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
			if(iIndex == 44 || iIndex == 648)
				ExtraThrowables_Set(client, iWeapon);
		
		}
	
	}
	
	iWeapon = GetPlayerWeaponSlot(client, 1);
	if(!IsValidEntity(iWeapon))
		return;
	
	int iIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
	switch(iIndex){
	
		case 222, 812, 833, 1121, 42, 159, 311, 433, 863, 1002, 58, 1083, 1105:
			ExtraThrowables_Set(client, iWeapon);
	
	}

}

stock void ExtraThrowables_Set(int client, int iWeapon){

	int iOffset		= GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
	int iAmmoTable	= FindSendPropInfo("CTFPlayer", "m_iAmmo");
	SetEntData(client, iAmmoTable +iOffset, g_iExtraThrowables_Amount, 4, true);

}