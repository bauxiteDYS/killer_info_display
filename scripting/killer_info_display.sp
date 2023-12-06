#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = {
	name		= "Killer Info Display for NT",
	author		= "Berni, gH0sTy, Smurfy1982, Snake60",
	description	= "Displays the health, the armor and the weapon of the player who has killed you",
	version		= 0.1.0,
	url		= "http://forums.alliedmods.net/showthread.php?p=670361",
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) 
{ 
    MarkNativeAsOptional("GetUserMessageType"); 
    return APLRes_Success; 
}

public OnPluginStart()
{	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	LoadTranslations("killer_info_display.phrases");
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client	= GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker	= GetClientOfUserId(GetEventInt(event, "attacker"));

	if (client == 0 || attacker == 0 || client == attacker) 
	{
		return Plugin_Continue;
	}

	decl
		String:weapon[32],
		String:unitType[8],
		String:distanceType[5];

	new
		Float:distance,
		armor;

	new healthLeft = GetClientHealth(attacker);

	GetEventString(event, "weapon", weapon, sizeof(weapon));		
	GetConVarString(cvDistancetype, distanceType, sizeof(distanceType));

	SetGlobalTransTarget(client);
	
	armor = Client_GetArmor(attacker);

	distance = Entity_GetDistance(client, attacker);
	distance = Math_UnitsToMeters(distance);
	Format(unitType, sizeof(unitType), "%t", "meters");
	
	// Print To Panel ?
	new Handle:panel= CreatePanel();
	decl String:buffer[128];
	Format(buffer, sizeof(buffer), "%t", "panel_killer", attacker);
	SetPanelTitle(panel, buffer);
	DrawPanelItem(panel, "", ITEMDRAW_SPACER);
		
	Format(buffer, sizeof(buffer), "%t", "panel_weapon", weapon);
	DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);
	
	Format(buffer, sizeof(buffer), "%t", "panel_health", healthLeft);
	DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);

	Format(buffer, sizeof(buffer), "%t", "panel_armor", "armor", armor);
	DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);
		
	Format(buffer, sizeof(buffer), "%t", "panel_distance", distance, unitType);
	DrawPanelItem(panel, buffer, ITEMDRAW_DEFAULT);
		
	DrawPanelItem(panel, "", ITEMDRAW_SPACER);

	SetPanelCurrentKey(panel, 10);
	SendPanelToClient(panel, client, Handler_DoNothing, 20);
	CloseHandle(panel);
	
	return Plugin_Continue;
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2) {}
