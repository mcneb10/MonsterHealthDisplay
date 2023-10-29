class MonsterHealthDisplay extends Mutator
config(MonsterHealthDisplay);

var config array<Name> DontDisplayHealthForTheseClassNames;
var float textYStart, textXStart;
var PlayerPawn player;


simulated function Tick(float DeltaTime) {
    if ( !bHUDMutator && Level.NetMode != NM_DedicatedServer )
        RegisterHUDMutator();
}

simulated function PostRender(Canvas c) {
	local vector hitLocation;
	local vector hitNormal;
	local vector traceBegin;
	local vector traceEnd;
	local Actor targetedActor;
	local Pawn target;
	local Actor tempActor;
	local bool displayThisActor;
	local int health;
	local int i;

	player = c.Viewport.Actor;
	textYStart = c.ClipY - (256 * ChallengeHUD(player.myHUD).Scale);

	c.SetPos(textXStart, textYStart);
	c.Font = ChallengeHUD(player.myHUD).MyFonts.GetBigFont(c.ClipX);
	SetDrawColor(c, 255, 0, 0, 255);

	// Thank god for the sniper rifle code
	// Get location of the player and adjust to eye height by adding Z axis of the eye height
	traceBegin = player.Location + (player.Eyeheight * vect(0, 0, 1));
	// Arcane
	traceEnd = traceBegin + (10000 * vector(player.AdjustAim(1000000, traceBegin, 0, False, False)));
	
	// Sniper Rifle Version:
	// targetedActor = player.TraceShot(hitLocation, hitNormal, traceEnd, traceBegin);

	// Send a beam out from the player's eyes
	// If it touches an actor return it
	// If the actor looks interesting, break out of the loop and use it as the actor being looked at
	foreach TraceActors(class'Actor', targetedActor, hitLocation, hitNormal, traceEnd, traceBegin) {
		if (Pawn(targetedActor) != None || targetedActor.bProjTarget || (targetedActor.bBlockPlayers && targetedActor.bBlockActors)) {
			if(targetedActor.IsA('Vehicle')) {
				// TODO: check passenger list
				 // Make sure the whole name of the object until the endquote is in there, not just one part
				if(InStr(targetedActor.GetPropertyText("Driver"),String(player)$"'")==-1&&InStr(targetedActor.GetPropertyText("Passengers"),String(player)$"'")==-1) {
					break;
				}
			} else {
				break;
			}
		}
	}
	if(targetedActor != None) {
		if(targetedActor.IsA('Vehicle')) {
				if(InStr(targetedActor.GetPropertyText("Driver"),String(player)$"'")!=-1||InStr(targetedActor.GetPropertyText("Passengers"),String(player)$"'")!=-1) {
					goto end;
				}
				// TODO: implement checks against the player being a passenger as well
		}
		health = Max(int(targetedActor.GetPropertyText("MHealth")), int(targetedActor.GetPropertyText("Health")));
		displayThisActor = health > 0;
		for(i = 0; i < DontDisplayHealthForTheseClassNames.Length; i++) {
			if(targetedActor.IsA(DontDisplayHealthForTheseClassNames[i])) {
				displayThisActor = False;
				break;
			}
		}
		if(targetedActor.isA('Pawn')) {
			target = Pawn(targetedActor).Enemy;
		}
		if(displayThisActor) {
			c.DrawText("You are looking at:"$targetedActor.GetHumanName());
			c.SetPos(textXStart, textYStart + 20);
			c.DrawText("Health:"@health);
			if(target != None) {
				c.SetPos(textXStart, textYStart + 40);
				c.DrawText("Target:"$target.GetHumanName());
				c.SetPos(textXStart, textYStart + 60);
				c.DrawText("Target Health:"@target.Health);
			} else if(targetedActor.isA('Vehicle')) {
					foreach AllActors(class'Actor', tempActor) {
						if(Pawn(tempActor) != None && InStr(targetedActor.GetPropertyText("Driver"), Pawn(tempActor).Name$"'") != -1) {
							break;
						}
					}
					if(tempActor == None) goto end;
					c.SetPos(textXStart, textYStart + 40);
					c.DrawText("Driver:"$tempActor.GetHumanName());
					//if(bool(targetedActor.GetPropertyText("bHasPassengers"))) {
					c.SetPos(textXStart, textYStart + 60);
					c.DrawText("Passengers:"$targetedActor.GetPropertyText("Passengers"));
					/* 	 TODO passengers
					for(i = 0; i < ; i++) {

						}
						*/
					//}
				
			}
		}
	}
	end:
	if (NextHUDMutator != None)
        NextHUDMutator.PostRender(c);
}

simulated function SetDrawColor(Canvas c, int r, int g, int b, int a) {
	c.DrawColor.R = r;
	c.DrawColor.G = g;
	c.DrawColor.B = b;
	c.DrawColor.A = a;
}

defaultproperties
{
	DontDisplayHealthForTheseClassNames=()
	textXStart=10
	textYStart=600
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=True
	bNetTemporary=True
}
