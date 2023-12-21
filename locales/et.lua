local Translations = {
    error = {
        lockpick_fail = "Ebaõnnestus",
        door_not_found = "Ei saadud mudeli hashi, kui uks on nähtamatu, siis suunake enda relvake uste poole või ukse poole!",
        same_entity = "Mõlemad uksed ei saa olla üks ja sama uks ",
        door_registered = "See uks on juba olemas!",
        door_identifier_exists = "See uks on juba teil seadistuses olemas. (%s)",
    },
    success = {
        lockpick_success = "Õnnestus"
    },
    general = {
        locked = "Lukus",
        unlocked = "Lahti",
        locked_button = "[E] - Lukus",
        unlocked_button = "[E] - Lahti",
        keymapping_description = "Tegele lukkudega",
        keymapping_remotetriggerdoor = "Kaugjuhi ust",
        locked_menu = "Lukus",
        pickable_menu = "Muukimis kõlblik",
        cantunlock_menu = 'Ei saa avada',
        hidelabel_menu = 'Peida ukse pealkiri',
        distance_menu = "Maksimaalne distants",
        item_authorisation_menu = "Ese millega ust lahti teha",
        citizenid_authorisation_menu = "CID autentimine",
        gang_authorisation_menu = "Rühmituse autentimine",
        job_authorisation_menu = "Töö autentimine",
        doortype_title = "Ukse tüüp",
        doortype_door = "Üks uks",
        doortype_double = "Kaheuskeline",
        doortype_sliding = "Üksik liikuv uks",
        doortype_doublesliding = "Kaheukseline liikuv uks",
        doortype_garage = "Garaaz",
        dooridentifier_title = "Tuvastaja",
        doorlabel_title = "Ukse pealkiri",
        configfile_title = "Konfiguratsiooni nimi",
        submit_text = "Nõustu",
        newdoor_menu_title = "Lisa uus uks",
        newdoor_command_description = "Lisa uus uks süsteemi",
        doordebug_command_description = "Debug mood peal",
        warning = "Hoiatus",
        created_by = "tehtud",
        warn_no_permission_newdoor = "%{player} (%{license}) proovis lisada ust ilma õigusteta (source: %{source})",
        warn_no_authorisation = "%{player} (%{license}) proovis avada ust ilma loata (Sent: %{doorID})",
        warn_wrong_doorid = "%{player} (%{license}) proovis uuendada ust vale identsusega (Sent: %{doorID})",
        warn_wrong_state = "%{player} (%{license}) proovis uuendada ust valese seisu (Sent: %{state})",
        warn_wrong_doorid_type = "%{player} (%{license}) ei saadetud õiget ukse identsust (Sent: %{doorID})",
        warn_admin_privilege_used = "%{player} (%{license}) avati uks meeskonna privileegidega"
    }
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})