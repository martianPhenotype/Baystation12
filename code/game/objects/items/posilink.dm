/**
 * Posilink lets a person (traitor) remote control a mindless IPC.
 * Mechanically it mind-swaps the person and gives them the option to delink.
 * Only the IPC's posilink actually processes when active.
 */
/obj/item/posilink
	name = "posilink"
	desc = "A wild contraption of positronic circuitry."
	icon = 'icons/obj/cypherkeys.dmi'
	icon_state = "ce_cypherkey"
	slot_flags = SLOT_EARS
	/// The remote control IPC.
	var/mob/living/carbon/human/control
	/// The bad-man controlling the IPC.
	var/mob/living/carbon/human/link_src
	/// The mind datum getting thrown around
	var/datum/mind/conscious
	/// The reciever worn by the IPC.
	var/obj/item/posilink/pair
	/// Designation for recognition.
	var/desg
	/// Time since posilinking.
	var/posilinked_time

/obj/item/posilink/Initialize()
	. = ..()
	desg = "[rand(100, 999)][uppertext(pick(GLOB.full_alphabet))]"
	name = "[name] ([desg])"
	verbs += /obj/item/posilink/proc/posilink

/obj/item/posilink/examine(mob/user)
	. = ..()
	if(pair)
		to_chat(user, SPAN_NOTICE("A small display on \the [src] reads <b>\"[pair.desg]\"</b>."))

/obj/item/posilink/use_tool(obj/item/tool, mob/user)
	if(istype(tool, /obj/item/posilink))
		var/obj/item/posilink/pairing = tool
		pairing.pair = src
		pair = pairing
		to_chat(user, SPAN_NOTICE("You link \the [src] to \the [pair]."))

/obj/item/posilink/Process()
	if(link_src) // Gibbing mainly.
		if(link_src.get_current_health() <= link_src.get_max_health() * 0.75)
			unlink(TRUE)
	else
		unlink()

	if(control.stat == DEAD)
		unlink()
	return

/obj/item/posilink/forceMove()
	. = ..()
	if(is_processing)
		unlink()
	else
		pair.unlink()

/// Initiates remote control
/obj/item/posilink/proc/posilink()
	set name = "Activate posilink"
	set desc = "Remote control a positronic chassis!"
	set category = "Posilink"
	set src in usr.contents

	if(ishuman(loc) && ishuman(pair.loc))
		link_src = loc
		conscious = link_src.mind
		control = pair.loc

		if((link_src.l_ear == src || link_src.r_ear == src) && (control.l_ear == pair || control.r_ear == pair))
			if(control.is_species(SPECIES_IPC))
				if(!control.mind)
					to_chat(link_src, SPAN_NOTICE("You activate \the [src], streaming your consciousness to \the [control]."))
					conscious.transfer_to(control)
					verbs -= /obj/item/posilink/proc/posilink
					pair.verbs -= /obj/item/posilink/proc/posilink
					pair.verbs += /obj/item/posilink/proc/unlink
					pair.posilinked_time = world.time
					pair.control = control
					pair.link_src = link_src

					START_PROCESSING(SSobj, pair)

					return TRUE
				else
					to_chat(link_src, SPAN_WARNING("\The [control] cannot override \a [control.internal_organs_by_name[BP_POSIBRAIN]]."))
					return FALSE
			else
				to_chat(link_src, SPAN_WARNING("\The [src] beeps but nothing happens."))
				return FALSE

		else
			to_chat(link_src, SPAN_WARNING("You must be wearing \the [src]!"))
			return FALSE
	else
		crash_with("A posilink was somehow triggered without someone!")
		return FALSE

/**
 * Unlinks the posilink.
 * This is done voluntarily by the posilink on the IPC, not the link_src!
 */
/obj/item/posilink/proc/unlink(hurt = FALSE)
	set name = "Deactivate posilink"
	set desc = "Return to your real body."
	set category = "Posilink"
	set src in usr.contents


	if(link_src)
		to_chat(control, FONT_LARGE(SPAN_DANGER("YOU SNAP BACK TO REALITY.")))
		conscious.transfer_to(link_src)

		if(!hurt)
			link_src.adjustBrainLoss(max)

	else
		to_chat(control, FONT_LARGE(SPAN_DANGER("YOUR CORPOREAL DEMISE DRAGS YOU AWAY.")))
		control.ghostize()

	sound_to(conscious.current, "sound/weapons/anime_sword.wav")

	verbs -= /obj/item/posilink/proc/unlink
	verbs += /obj/item/posilink/proc/posilink
	pair.verbs += /obj/item/posilink/proc/posilink

	control = null
	link_src = null
	conscious = null
	pair.control = null
	pair.link_src = null
	pair.conscious = null

	STOP_PROCESSING(SSobj, src)