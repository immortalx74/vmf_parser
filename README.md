# vmf_parser

Simple VMF (Valve Map Format) parser for a personal game project.
It reads brushes with "NODRAW" to be used as AABB collision volumes, as well as "info_player_start", "game_end" and "vgui_world_text_panel".
Those last three are used as positions for level-start, level-end, and collectable-coins, respectively.
