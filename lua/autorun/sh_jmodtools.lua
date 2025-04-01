if SERVER then
	resource.AddWorkshop("3445636397")
end

local ShouldMergeRecipes = CreateConVar("jmod_tools_merge_recipes", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Auto generates recipes for JMod Additional Tools items")

hook.Add("JMod_PostLuaConfigLoad", "JMod_HL2_PostLoadConfig", function(Config)
	local JModToolsRecipes = {
		["EZ Binoculars"] = {
			craftingReqs = {
				[JMod.EZ_RESOURCE_TYPES.BASICPARTS] = 20,
				[JMod.EZ_RESOURCE_TYPES.STEEL] = 15,
				[JMod.EZ_RESOURCE_TYPES.GLASS] = 5,
			},
			results = "ent_mann_jmod_ezbinoculars",
			category = "Tools",
			craftingType = { "workbench" },
			description = "With it you will be able to see further."
		},
		["EZ Portable Radio"] = {
			craftingReqs = {
				[JMod.EZ_RESOURCE_TYPES.BASICPARTS] = 20,
				[JMod.EZ_RESOURCE_TYPES.PLASTIC] = 15,
				[JMod.EZ_RESOURCE_TYPES.POWER] = 30,
			},
			results = "ent_mann_jmod_ezradio",
			category = "Tools",
			craftingType = { "fabricator" },
			description = "Supply Radio in your pocket."
		},
		["EZ Wrench"] = {
			craftingReqs = {
				[JMod.EZ_RESOURCE_TYPES.BASICPARTS] = 20,
				[JMod.EZ_RESOURCE_TYPES.STEEL] = 40,
			},
			results = "ent_mann_jmod_ezwrench",
			category = "Tools",
			craftingType = { "workbench" },
			description = "Can repair anything that is heavy damaged."
		},
		["EZ Fire Extinguisher"] = {
			craftingReqs = {
				[JMod.EZ_RESOURCE_TYPES.STEEL] = 60,
				[JMod.EZ_RESOURCE_TYPES.CHEMICALS] = 25,
				[JMod.EZ_RESOURCE_TYPES.WATER] = 50,
			},
			results = "ent_mann_jmod_ezextinguisher",
			category = "Tools",
			craftingType = { "workbench" },
			description = "A portable fire extinguisher that consumes gas with water, handles napalm well."
		},
		["EZ Match Box"] = {
			craftingReqs = {
				[JMod.EZ_RESOURCE_TYPES.WOOD] = 5,
				[JMod.EZ_RESOURCE_TYPES.PROPELLANT] = 5,
			},
			results = "ent_mann_jmod_ezmatchbox",
			category = "Other",
			craftingType = { "workbench", "craftingtable" },
			description = "Make fire like in 1 million BC."
		},
	}

	if ShouldMergeRecipes:GetBool() then
		table.Merge(JMod.Config.Craftables, JModToolsRecipes, true)
		print("JMOD Additional Tools: recipes merged")
	end
end)