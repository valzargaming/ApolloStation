/proc/alien_queen_exists(var/ignore_self,var/mob/living/carbon/human/self)
	for(var/mob/living/carbon/human/Q in living_mob_list)
		if(self && ignore_self && self == Q)
			continue
		if(Q.species.name != "Xenomorph Queen")
			continue
		if(!Q.key || !Q.client || Q.stat)
			continue
		return 1
	return 0

/mob/living/carbon/human/proc/gain_phoron(var/amount)

	var/datum/organ/internal/xenos/phoronvessel/I = internal_organs_by_name["phoron vessel"]
	if(!istype(I)) return

	if(amount)
		I.stored_phoron += amount
	I.stored_phoron = max(0,min(I.stored_phoron,I.max_phoron))

/mob/living/carbon/human/proc/check_alien_ability(var/cost,var/needs_foundation,var/needs_organ)
	// If it's dead it should stay dead. Might want to prevent stunned aliens too.
	if(src.stat == 2)
		return

	var/datum/organ/internal/xenos/phoronvessel/P = internal_organs_by_name["phoron vessel"]
	if(!istype(P))
		src << "<span class='danger'>Your phoron vessel has been removed!</span>"
		return

	if(needs_organ)
		var/datum/organ/internal/I = internal_organs_by_name[needs_organ]
		if(!I)
			src << "<span class='danger'>Your [needs_organ] has been removed!</span>"
			return
		else if((I.status & ORGAN_CUT_AWAY) || I.is_broken())
			src << "<span class='danger'>Your [needs_organ] is too damaged to function!</span>"
			return

	if(P.stored_phoron < cost)
		src << "<span class='alert'> You don't have enough phoron stored to do that.</span>"
		return 0

	if(needs_foundation)
		var/turf/T = get_turf(src)
		var/has_foundation
		if(T)
			//TODO: Work out the actual conditions this needs.
			if(!(istype(T,/turf/space)))
				has_foundation = 1
		if(!has_foundation)
			src << "<span class='alert'> You need a solid foundation to do that on.</span>"
			return 0

	P.stored_phoron -= cost
	return 1

// Free abilities.
/mob/living/carbon/human/proc/transfer_phoron(mob/living/carbon/human/M as mob in oview())
	set name = "Transfer phoron"
	set desc = "Transfer phoron to another alien"
	set category = "Abilities"

	if (get_dist(src,M) >= 2)
		src << "<span class='alium'>You need to be closer.</span>"
		return

	var/datum/organ/internal/xenos/phoronvessel/I = M.internal_organs_by_name["phoron vessel"]
	if(!istype(I))
		src << "<span class='alium'>Their phoron vessel is missing.</span>"
		return

	var/amount = input("Amount:", "Transfer phoron to [M]") as num
	if (amount)
		amount = abs(round(amount))
		if(check_alien_ability(amount,0,"phoron vessel"))
			M.gain_phoron(amount)
			M << "<span class='alium'>[src] has transfered [amount] phoron to you.</span>"
			src << "<span class='alium'>You have transferred [amount] phoron to [M].</span>"
	return

// Queen verbs.
/mob/living/carbon/human/proc/lay_egg()

	set name = "Lay Egg (75)"
	set desc = "Lay an egg to produce huggers to impregnate prey with."
	set category = "Abilities"

	if(!config.aliens_allowed)
		src << "You begin to lay an egg, but hesitate. You suspect it isn't allowed."
		//verbs -= /mob/living/carbon/human/proc/lay_egg
		return

	if(locate(/obj/effect/alien/egg) in get_turf(src))
		src << "There's already an egg here."
		return

	if(check_alien_ability(75,1,"egg sac"))
		visible_message("<span class='alium'><B>[src] has laid an egg!</B></span>")
		new /obj/effect/alien/egg(loc)

	return

// Drone verbs.
/mob/living/carbon/human/proc/evolve()
	set name = "Evolve (500)"
	set desc = "Produce an interal egg sac capable of spawning children. Only one queen can exist at a time."
	set category = "Abilities"

	if(alien_queen_exists())
		src << "<span class='notice'>We already have an active queen.</span>"
		return

	if(check_alien_ability(500))
		visible_message("<span class='alium'><B>[src] begins to twist and contort!</B></span>", "<span class='alium'>You begin to evolve!</span>")
		src.set_species("Xenomorph Queen")

	return

/mob/living/carbon/human/proc/plant()
	set name = "Plant Weeds (50)"
	set desc = "Plants some alien weeds"
	set category = "Abilities"

	if(check_alien_ability(50,1,"resin spinner"))
		visible_message("<span class='alium'><B>[src] has planted some alien weeds!</B></span>")
		new /obj/effect/alien/weeds/node(loc)
	return

/mob/living/carbon/human/proc/corrosive_acid(O as obj|turf in oview(1)) //If they right click to corrode, an error will flash if its an invalid target./N
	set name = "Corrosive Acid (200)"
	set desc = "Drench an object in acid, destroying it over time."
	set category = "Abilities"

	if(!O in oview(1))
		src << "<span class='alium'>[O] is too far away.</span>"
		return

	// OBJ CHECK
	if(isobj(O))
		var/obj/I = O
		if(I.unacidable)	//So the aliens don't destroy energy fields/singularies/other aliens/etc with their acid.
			src << "<span class='alium'>You cannot dissolve this object.</span>"
			return
	// TURF CHECK
	else if(istype(O, /turf/simulated/wall/alloy/reinforced) || istype(O, /turf/simulated/floor/engine))
		src << "<span class='alium'>You cannot dissolve this object.</span>"
		return

	if(check_alien_ability(200,0,"acid gland"))
		new /obj/effect/alien/acid(get_turf(O), O)
		visible_message("<span class='alium'><B>[src] vomits globs of vile stuff all over [O]. It begins to sizzle and melt under the bubbling mess of acid!</B></span>")

	return

/mob/living/carbon/human/proc/neurotoxin(mob/target as mob in oview())
	set name = "Spit Neurotoxin (50)"
	set desc = "Spits neurotoxin at someone, paralyzing them for a short time if they are not wearing protective gear."
	set category = "Abilities"

	if(!check_alien_ability(50,0,"acid gland"))
		return

	if(stat || paralysis || stunned || weakened || lying || restrained() || buckled)
		src << "You cannot spit neurotoxin in your current state."
		return

	visible_message("<span class='warning'>[src] spits neurotoxin at [target]!</span>", "<span class='alium'>You spit neurotoxin at [target].</span>")

	//I'm not motivated enough to revise this. Prjectile code in general needs update.
	// Maybe change this to use throw_at? ~ Z
	var/turf/T = loc
	var/turf/U = (istype(target, /atom/movable) ? target.loc : target)

	if(!U || !T)
		return
	while(U && !istype(U,/turf))
		U = U.loc
	if(!istype(T, /turf))
		return
	if (U == T)
		usr.bullet_act(new /obj/item/projectile/energy/neurotoxin(usr.loc), get_organ_target())
		return
	if(!istype(U, /turf))
		return

	var/obj/item/projectile/energy/neurotoxin/A = new /obj/item/projectile/energy/neurotoxin(usr.loc)
	A.current = U
	A.yo = U.y - T.y
	A.xo = U.x - T.x
	A.process()
	return

/mob/living/carbon/human/proc/resin() // -- TLE
	set name = "Secrete Resin (75)"
	set desc = "Secrete tough malleable resin."
	set category = "Abilities"

	var/choice = input("Choose what you wish to shape.","Resin building") as null|anything in list("resin door","resin wall","resin membrane","resin nest") //would do it through typesof but then the player choice would have the type path and we don't want the internal workings to be exposed ICly - Urist
	if(!choice)
		return

	if(!check_alien_ability(75,1,"resin spinner"))
		return

	visible_message("<span class='warning'><B>[src] vomits up a thick purple substance and begins to shape it!</B></span>", "<span class='alium'>You shape a [choice].</span>")
	switch(choice)
		if("resin door")
			new /obj/structure/mineral_door/resin(loc)
		if("resin wall")
			new /obj/effect/alien/resin/wall(loc)
		if("resin membrane")
			new /obj/effect/alien/resin/membrane(loc)
		if("resin nest")
			new /obj/structure/bed/nest(loc)
	return

/mob/living/carbon/human/proc/nightvision()
	set name = "Toggle Nightvision (10)"
	set desc = "Toggles nightvision. Costs phoron to keep active."
	set category = "Abilities"

	if(src.see_invisible != 15)
		src.see_invisible = 15
		src.see_in_dark = 20
	else
		src.see_invisible = 25
		src.see_in_dark = 2

	spawn(0)
		while(src && src.see_invisible == 15)
			if(src.check_alien_ability(5,0,""))
			else
				src.see_invisible = 25
				src.see_in_dark = 2
			sleep(60)

	return

/mob/living/carbon/human/proc/camo()
	set name = "Toggle Camouflage (20)"
	set desc = "Toggles camouflage. Costs phoron to keep active."
	set category = "Abilities"

	if(src.alpha != 100)
		src.alpha = 100
	else
		src.alpha = 255


	spawn(0)
		while(src && src.alpha == 100)
			if(src.check_alien_ability(15,0,""))
			else
				src.alpha = 255
			sleep(60)

	return