/* Beds... get your mind out of the gutter, they're for sleeping!
 * Contains:
 * 		Beds
 *		Roller beds
 */

/*
 * Beds
 */
/obj/structure/bed
	name = "bed"
	desc = "This is used to lie in, sleep in or strap on."
	icon = 'icons/obj/furniture.dmi'
	icon_state = "bed"
	anchored = 1
	var/mob/living/buckled_mob
	var/movable = 0 // For mobility checks

/obj/structure/bed/psych
	name = "psychiatrists couch"
	desc = "For prime comfort during psychiatric evaluations."
	icon_state = "psychbed"

/obj/structure/bed/alien
	name = "resting contraption"
	desc = "This looks similar to contraptions from earth. Could aliens be stealing our technology?"
	icon_state = "abed"

/obj/structure/bed/Destroy()
	unbuckle()
	..()
	return

/obj/structure/bed/attack_hand(mob/user as mob)
	manual_unbuckle(user)
	return

/obj/structure/bed/MouseDrop(atom/over_object)
	return

/obj/structure/bed/MouseDrop_T(mob/M as mob, mob/user as mob)
	if(!istype(M)) return
	buckle_mob(M, user)
	return

/obj/structure/bed/proc/afterbuckle(mob/M as mob) // Called after somebody buckled / unbuckled
	return


/obj/structure/bed/proc/unbuckle()
	if(buckled_mob)
		if(buckled_mob.buckled == src)	//this is probably unneccesary, but it doesn't hurt
			buckled_mob.buckled = null
			buckled_mob.anchored = initial(buckled_mob.anchored)
			buckled_mob.update_canmove()

			var/M = buckled_mob
			buckled_mob = null

			afterbuckle(M)
	return

/obj/structure/bed/proc/manual_unbuckle(mob/user as mob)
	if(buckled_mob)
		if(buckled_mob.buckled == src)
			if(buckled_mob != user)
				buckled_mob.visible_message(\
					"<span class='notice'> [buckled_mob.name] was unbuckled by [user.name]!</span>",\
					"You were unbuckled from [src] by [user.name].",\
					"You hear metal clanking")
			else
				buckled_mob.visible_message(\
					"<span class='notice'> [buckled_mob.name] unbuckled \himself!</span>",\
					"You unbuckle yourself from [src].",\
					"You hear metal clanking")
			unbuckle()
			src.add_fingerprint(user)
			return 1

	return 0

/obj/structure/bed/proc/buckle_mob(mob/M as mob, mob/user as mob)
	if (!ticker)
		user << "You can't buckle anyone in before the game starts."
	if ( !ismob(M) || (get_dist(src, user) > 1) || (M.loc != src.loc) || user.restrained() || user.lying || user.stat || M.buckled || M.pinned.len || istype(user, /mob/living/silicon/pai) )
		return

	if (istype(M, /mob/living/carbon/slime))
		user << "The [M] is too squishy to buckle in."
		return

	unbuckle()

	if (M == usr)
		M.visible_message(\
			"<span class='notice'> [M.name] buckles in!</span>",\
			"You buckle yourself to [src].",\
			"You hear metal clanking")
	else
		M.visible_message(\
			"<span class='notice'> [M.name] is buckled in to [src] by [user.name]!</span>",\
			"You are buckled in to [src] by [user.name].",\
			"You hear metal clanking")
	M.buckled = src
	M.loc = src.loc
	M.set_dir(src.dir)
	M.update_canmove()
	src.buckled_mob = M
	src.add_fingerprint(user)
	afterbuckle(M)
	return

/*
 * Roller beds
 */
/obj/structure/bed/roller
	name = "roller bed"
	icon = 'icons/obj/rollerbed.dmi'
	icon_state = "down"
	anchored = 0

/obj/structure/bed/roller/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W,/obj/item/roller_holder))
		if(buckled_mob)
			manual_unbuckle()
		else
			visible_message("[user] collapses \the [src.name].")
			new/obj/item/roller(get_turf(src))
			spawn(0)
				qdel(src)
		return
	..()

/obj/item/roller
	name = "roller bed"
	desc = "A collapsed roller bed that can be carried around."
	icon = 'icons/obj/rollerbed.dmi'
	icon_state = "folded"
	w_class = 4.0 // Can't be put in backpacks. Oh well.

/obj/item/roller/attack_self(mob/user)
		var/obj/structure/bed/roller/R = new /obj/structure/bed/roller(user.loc)
		R.add_fingerprint(user)
		qdel(src)

/obj/item/roller/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if(istype(W,/obj/item/roller_holder))
		var/obj/item/roller_holder/RH = W
		if(!RH.held)
			user << "<span class='notice'> You collect the roller bed.</span>"
			src.loc = RH
			RH.held = src
			return

	..()

/obj/item/roller_holder
	name = "roller bed rack"
	desc = "A rack for carrying a collapsed roller bed."
	icon = 'icons/obj/rollerbed.dmi'
	icon_state = "folded"
	var/obj/item/roller/held

/obj/item/roller_holder/New()
	..()
	held = new /obj/item/roller(src)

/obj/item/roller_holder/attack_self(mob/user as mob)

	if(!held)
		user << "<span class='notice'> The rack is empty.</span>"
		return

	user << "<span class='notice'> You deploy the roller bed.</span>"
	var/obj/structure/bed/roller/R = new /obj/structure/bed/roller(user.loc)
	R.add_fingerprint(user)
	qdel(held)
	held = null


/obj/structure/bed/roller/Move()
	..()
	if(buckled_mob)
		if(buckled_mob.buckled == src)
			buckled_mob.loc = src.loc
		else
			buckled_mob = null

/obj/structure/bed/roller/buckle_mob(mob/M as mob, mob/user as mob)
	if ( !ismob(M) || (get_dist(src, user) > 1) || (M.loc != src.loc) || user.restrained() || user.lying || user.stat || M.buckled || istype(usr, /mob/living/silicon/pai) )
		return
	M.pixel_y = 6
	M.old_y = 6
	density = 1
	icon_state = "up"
	..()
	return

/obj/structure/bed/roller/manual_unbuckle(mob/user as mob)
	if(buckled_mob)
		if(buckled_mob.buckled == src)	//this is probably unneccesary, but it doesn't hurt
			buckled_mob.pixel_y = 0
			buckled_mob.old_y = 0
			buckled_mob.anchored = initial(buckled_mob.anchored)
			buckled_mob.buckled = null
			buckled_mob.update_canmove()
			buckled_mob = null
	density = 0
	icon_state = "down"
	..()
	return

/obj/structure/bed/roller/MouseDrop(over_object, src_location, over_location)
	..()
	if((over_object == usr && (in_range(src, usr) || usr.contents.Find(src))))
		if(!ishuman(usr))	return
		if(buckled_mob)	return 0
		visible_message("[usr] collapses \the [src.name].")
		new/obj/item/roller(get_turf(src))
		spawn(0)
			qdel(src)
		return
