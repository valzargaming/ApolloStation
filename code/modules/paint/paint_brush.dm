/obj/item/weapon/paint_brush
	desc = "Used for the popular hobby of watching paint dry."
	name = "paint brush"
	icon = 'icons/obj/items.dmi'
	icon_state = "paintbrush"
	var/icon_overlay = "paintbrush_overlay"
	force = 3.0
	throwforce = 6.0
	throw_speed = 5
	throw_range = 10
	w_class = 3.0
	attack_verb = list( "whapped", "slapped", "hit", "whacked" )

	var/paint_color = null
	var/list/paint_modes = list( "Base" = "base", "Bottom Stripe" = "stripe0", "Top Stripe" = "stripe1" )
	var/paint_mode = "base" // Different paint modes

	var/volume = 0
	var/max_volume = 5

/obj/item/weapon/paint_brush/New()
	..()

	create_reagents(5)

/obj/item/weapon/paint_brush/attack_self(mob/user as mob)
	var/choice = input( user, "What type do you want to paint?", "Choose a Paint Mode" ) as null|anything in paint_modes

	if( choice )
		paint_mode = paint_modes[choice]

/obj/item/weapon/paint_brush/update_icon()
	overlays.Cut()

	if( !paint_color )
		return

	var/icon/I = new( icon = icon, icon_state = icon_overlay )
	var/overlay_color = paint_colors[paint_color]

	// Adding the color
	I.Blend( overlay_color, ICON_MULTIPLY )

	// Layering it on the composite image

	overlays += image( I )
	qdel( I )

	return

/obj/item/weapon/paint_brush/examine(mob/user)
	. = ..(user)

	if( paint_color )
		user << "It is covered with [paint_color] paint."

/obj/item/weapon/paint_brush/proc/wash()
	paint_color = null
	volume = 0

	update_icon()

/obj/item/weapon/paint_brush/proc/transferPaint( var/amount, var/color )
	if( !color )
		return -2
	if( volume == max_volume )
		return -1
	if( amount <=  0 )
		return 0

	volume = min( max_volume, max( 0, amount+volume ))
	paint_color = color

	update_icon()

	return 1

/obj/item/weapon/paint_brush/proc/paint( var/atom/A, var/mob/user )
	if( !volume )
		if( user )
			user << "There's no paint left on \the [src]!"
		return 0

	if( istype( A, /turf/simulated/wall ))
		var/turf/simulated/wall/W = A
		W.paint( paint_color, paint_mode )
		volume = max( 0, volume-1 )
		if( user )
			user << "You paint the wall with [paint_color] paint."
		if( !volume )
			paint_color = null
			update_icon()

