-- ============================================================
-- FS25_RealTireWear.lua
-- by Marcus (Cobra Modding)
--
-- Version 1.0.0.0
--
--
-- Individueller Reifenverschleiss
--
-- Faktoren:
-- - Strecke
-- - Schlupf
-- - Radlast
-- - Geschwindigkeit
-- - Untergrund
--
-- Zusaetzlich:
-- - Progressive Grip-Abnahme
-- - Echter physikalischer Grip pro Rad
-- - Reifenausfall ab sehr hohem Verschleiss
-- - Sichtbarer Shader-Verschleiss (nur Rad,keine Crawlers)
--
--
-- Keine Änderung am Skript ohne meine Erlaubnis.
-- ============================================================

if TireWear ~= nil
    and TireWear.__realTireWearCoreLoaded == true then

    return

end

TireWear = TireWear or {}
TireWear.__realTireWearCoreLoaded = true

TireWear.MOD_NAME =
    g_currentModName

TireWear.SPEC_NAME =
    g_currentModName .. ".tireWear"

TireWear.DEFAULT_LIFETIME =
    500000

TireWear.VISUAL_START =
    0.10

TireWear.MAX_TREAD_DEPTH_RATIO =
    0.055

TireWear.VISUAL_WEAR_EXPONENT =
    0.70

TireWear.PHYSICS_TREAD_LOSS_FACTOR =
    0.85

TireWear.PHYSICS_RADIUS_EPSILON =
    0.0005

TireWear.GRIP_NEW =
    1.00

TireWear.GRIP_WORN =
    0.80

TireWear.GRIP_CRITICAL =
    0.55

TireWear.GRIP_FULLY_WORN =
    0.40

TireWear.MAX_SLIP_FACTOR =
    2.25

TireWear.LATERAL_SLIP_WEIGHT =
    0.70

TireWear.MIN_LOAD_FACTOR =
    0.75

TireWear.MAX_LOAD_FACTOR =
    1.60

TireWear.MAX_SPEED_FACTOR =
    1.30

TireWear.GROUND_FACTOR_ROAD =
    1.00

TireWear.GROUND_FACTOR_HARD =
    1.08

TireWear.GROUND_FACTOR_FIELD =
    1.15

TireWear.GROUND_FACTOR_SOFT =
    1.25

TireWear.MAX_TOTAL_WEAR_FACTOR =
    8.0

TireWear.SAVEGAME_KEY =
    "realTireWear"

TireWear.NETWORK_SYNC_DEBUG =
    false

TireWear.NETWORK_SYNC_DEBUG_BUCKETS =
    10

TireWear.MATERIAL_NAME =
    "REAL_TIRE_WEAR"

TireWear.TF8181_MATERIAL_NAME =
    "REAL_TIRE_WEAR_TF8181"

TireWear.T510_MATERIAL_NAME =
    "REAL_TIRE_WEAR_T510"

TireWear.MATERIAL_HOLDER_FILENAME =
    Utils.getFilename(
        "materialHolder/tireMaterialHolder.i3d",
        g_currentModDirectory
    )

TireWear.materialHolderRegistered =
    false

TireWear.materialMissingWarningShown =
    false

TireWear.CUSTOM_MAP_NAMES = {
    "detailSpecular",
    "detailNormal",
    "detailDiffuse",
    "dirtSpecular",
    "dirtNormal",
    "dirtDiffuse",
    "waterDroplets"
}

TireWear.MATERIAL_CUSTOM_PARAMETER_NAMES = {
    "scratches_dirt_snow_wetness",
    "dirtColor",
    "colorScale",
    "smoothnessScale",
    "metalnessScale",
    "clearCoatIntensity",
    "clearCoatSmoothness",
    "porosity",
    "alphaBlendingClipThreshold",
    "offsetUV",
    "uvCenterSize",
    "uvScale"
}

function TireWear.clamp(
    value,
    minimum,
    maximum
)

    return math.max(
        minimum,
        math.min(
            maximum,
            value
        )
    )

end


function TireWear.lerp(
    a,
    b,
    t
)

    t =
        TireWear.clamp(
            t,
            0,
            1
        )

    return a
        +
        (
            b - a
        )
        *
        t

end


function TireWear.log(
    text,
    ...
)
end

function TireWear.getVehicleSavegameBaseKey(
    key
)

    if key == nil then
        return nil
    end

    local baseKey =
        string.match(
            tostring(
                key
            ),
            "^(vehicles%.vehicle%(%d+%))"
        )

    return baseKey

end


function TireWear.getSavegameKey(
    baseKey
)

    if baseKey == nil then
        return nil
    end

    return baseKey
        ..
        "."
        ..
        TireWear.SAVEGAME_KEY

end


function TireWear.getWheelPhysicsValue(
    tire,
    name,
    defaultValue
)

    if tire == nil
        or tire.wheel == nil then

        return defaultValue

    end

    local wheel =
        tire.wheel

    local physics =
        wheel.physics

    if physics ~= nil
        and physics[name] ~= nil then

        return physics[name]

    end

    if wheel[name] ~= nil then

        return wheel[name]

    end

    return defaultValue

end

function TireWear.prerequisitesPresent(
    specializations
)

    return SpecializationUtil.hasSpecialization(
        Wheels,
        specializations
    )

end

function TireWear.registerMaterialHolder()

    if TireWear.materialHolderRegistered then
        return
    end

    if g_materialManager == nil then

        Logging.warning(
            "[RealTireWear] g_materialManager noch nicht vorhanden"
        )

        return

    end

    if g_materialManager.addModMaterialHolder == nil then

        Logging.warning(
            "[RealTireWear] addModMaterialHolder nicht vorhanden"
        )

        return

    end

    g_materialManager:addModMaterialHolder(
        TireWear.MATERIAL_HOLDER_FILENAME
    )

    TireWear.materialHolderRegistered =
        true

    TireWear.log(
        "MaterialHolder registriert: %s",
        TireWear.MATERIAL_HOLDER_FILENAME
    )

end

function TireWear.initSpecialization()

    TireWear.registerMaterialHolder()

    local schema =
        Vehicle.xmlSchema

    schema:setXMLSpecializationType(
        "TireWear"
    )

    schema:register(
        XMLValueType.FLOAT,
        "vehicle.tireWear#lifetime",
        "Reifenlebensdauer in Metern",
        TireWear.DEFAULT_LIFETIME
    )

    schema:register(
        XMLValueType.BOOL,
        "vehicle.tireWear#enabled",
        "Reifenverschleiss aktiv",
        true
    )

    schema:setXMLSpecializationType()

    local savegameSchema =
        Vehicle.xmlSchemaSavegame

    savegameSchema:register(XMLValueType.BOOL, "vehicles.vehicle(?).realTireWear.wheel(?)#airLeak", "Punctured tire", false)

    savegameSchema:register(
        XMLValueType.FLOAT,
        "vehicles.vehicle(?).realTireWear.wheel(?)#wear",
        "Real Tire Wear Reifenverschleiss",
        0
    )


end

function TireWear.registerFunctions(
    vehicleType
)

    SpecializationUtil.registerFunction(
        vehicleType,
        "getTireWear",
        TireWear.getTireWear
    )

    SpecializationUtil.registerFunction(
        vehicleType,
        "repairTires",
        TireWear.repairTires
    )

end

function TireWear.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSpeedLimit", TireWear.getSpeedLimit)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "showInfo", TireWear.showInfo)
end

function TireWear.isServiceableWheel(tire)
    if tire == nil or tire.wheel == nil then return false end
    if TireReplaceEvent ~= nil and TireReplaceEvent.isCrawlerWheel(tire) then
        return true
    end
    for _, visual in ipairs(tire.wheel.visualWheels or {}) do
        for _, part in ipairs(visual.visualParts or {}) do
            if WheelVisualPartTire ~= nil and part.isa ~= nil
                and part:isa(WheelVisualPartTire) then return true end
        end
    end
    return false
end

function TireWear:showInfo(superFunc, box)
    local spec = self.spec_tireWear
    if spec == nil or spec.enabled ~= true then
        return superFunc(self, box)
    end

    local wear, _, count =
        TireReplaceEvent.getTireData(
            self,
            TireReplaceEvent.MODE_ALL
        )

    if count <= 0 then
        return superFunc(self, box)
    end

    local function addTireWearLine()
        local label =
            g_i18n:getText(
                "rtw_display_title",
                TireWear.MOD_NAME
            )

        local value =
            string.format(
                "%d %%",
                math.floor(
                    TireWear.clamp(
                        wear,
                        0,
                        1
                    )
                    * 100
                    + 0.5
                )
            )

        box:addLine(
            label,
            value
        )
    end

    local damageLabel = g_i18n:getText("infohud_damage")
    local added = false
    local proxy = setmetatable({}, {
        __index = function(_, key)
            local member = box[key]
            if type(member) == "function" then
                return function(_, ...)
                    return member(box, ...)
                end
            end
            return member
        end,
        __newindex = function(_, key, value)
            box[key] = value
        end
    })

    rawset(proxy, "addLine", function(_, key, ...)
        box:addLine(key, ...)
        if key == damageLabel and not added then
            addTireWearLine()
            added = true
        end
    end)

    superFunc(self, proxy)
    if not added then
        addTireWearLine()
    end
end

function TireWear.registerEventListeners(
    vehicleType
)
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", TireWear)
    SpecializationUtil.registerEventListener(
        vehicleType,
        "onLoad",
        TireWear
    )

    SpecializationUtil.registerEventListener(
        vehicleType,
        "onPostLoad",
        TireWear
    )

    SpecializationUtil.registerEventListener(
        vehicleType,
        "onUpdateTick",
        TireWear
    )

    SpecializationUtil.registerEventListener(
        vehicleType,
        "saveToXMLFile",
        TireWear
    )

    SpecializationUtil.registerEventListener(
        vehicleType,
        "onWriteStream",
        TireWear
    )

    SpecializationUtil.registerEventListener(
        vehicleType,
        "onReadStream",
        TireWear
    )

end

function TireWear.getHolderMaterial(
    materialName
)

    if g_materialManager == nil then
        return nil
    end

    materialName =
        materialName
        or TireWear.MATERIAL_NAME

    local materialId =
        g_materialManager:getBaseMaterialByName(
            materialName
        )

    if materialId == nil then

        if not TireWear.materialMissingWarningShown then

            TireWear.materialMissingWarningShown =
                true

            Logging.warning(
                "[RealTireWear] Material '%s' noch nicht geladen",
                materialName
            )

        end

        return nil

    end

    TireWear.materialMissingWarningShown =
        false

    return materialId

end

function TireWear.materialFilenameMatches(
    filename,
    needle
)

    if filename == nil
        or filename == ""
        or needle == nil
        or needle == "" then

        return false

    end

    filename =
        string.lower(
            tostring(
                filename
            )
        )

    filename =
        string.gsub(
            filename,
            "\\",
            "/"
        )

    return string.find(
        filename,
        needle,
        1,
        true
    ) ~= nil

end

function TireWear.getCompatibleHolderMaterialName(
    originalMaterialId,
    sourceFilename
)

    if TireWear.materialFilenameMatches(
        sourceFilename,
        "/trelleborg/t510/"
    ) then

        return TireWear.T510_MATERIAL_NAME

    end

    if originalMaterialId == nil
        or originalMaterialId == 0 then

        return TireWear.MATERIAL_NAME

    end

    local materialFilenames =
        {}

    if getMaterialDiffuseMapFilename ~= nil then
        materialFilenames[#materialFilenames + 1] =
            getMaterialDiffuseMapFilename(
                originalMaterialId
            )
    end

    if getMaterialNormalMapFilename ~= nil then
        materialFilenames[#materialFilenames + 1] =
            getMaterialNormalMapFilename(
                originalMaterialId
            )
    end

    if getMaterialGlossMapFilename ~= nil then
        materialFilenames[#materialFilenames + 1] =
            getMaterialGlossMapFilename(
                originalMaterialId
            )
    end

    if getMaterialCustomMapFilename ~= nil then

        for _, mapName in ipairs(
            TireWear.CUSTOM_MAP_NAMES
        ) do

            materialFilenames[#materialFilenames + 1] =
                getMaterialCustomMapFilename(
                    originalMaterialId,
                    mapName
                )

        end

    end

    for _, filename in ipairs(
        materialFilenames
    ) do

        if TireWear.materialFilenameMatches(
            filename,
            "tf8181_normal"
        ) then

            return TireWear.TF8181_MATERIAL_NAME

        end

        if TireWear.materialFilenameMatches(
            filename,
            "/trelleborg/t510/"
        )
            or TireWear.materialFilenameMatches(
                filename,
                "t510_"
            ) then

            return TireWear.T510_MATERIAL_NAME

        end

    end

    return TireWear.MATERIAL_NAME

end

function TireWear.getWheelDimensions(
    tire
)

    local radius =
        1.0

    local width =
        0.6

    if tire == nil then
        return radius, width
    end

    local wheel =
        tire.wheel

    if wheel == nil then
        return radius, width
    end

    if wheel.visualWheels ~= nil
        and wheel.visualWheels[1] ~= nil then

        local visualWheel =
            wheel.visualWheels[1]

        if visualWheel.radius ~= nil then

            radius =
                tonumber(
                    visualWheel.radius
                )
                or radius

        end

        if visualWheel.width ~= nil then

            width =
                tonumber(
                    visualWheel.width
                )
                or width

        end

    end

    if wheel.physics ~= nil then

        local originalPhysicsRadius =
            tonumber(
                tire.originalPhysicsRadius
            )

        if originalPhysicsRadius == nil
            or originalPhysicsRadius <= 0 then

            originalPhysicsRadius =
                tonumber(
                    wheel.physics.radiusOriginal
                )

        end

        if originalPhysicsRadius == nil
            or originalPhysicsRadius <= 0 then

            originalPhysicsRadius =
                tonumber(
                    wheel.physics.radius
                )

        end

        if originalPhysicsRadius ~= nil
            and originalPhysicsRadius > 0 then

            radius =
                originalPhysicsRadius

        end

    end

    radius =
        math.max(
            radius,
            0.1
        )

    width =
        math.max(
            width,
            0.1
        )

    return radius,
           width

end

function TireWear.getOriginalPhysicsRadius(
    tire
)

    if tire == nil
        or tire.wheel == nil
        or tire.wheel.physics == nil then

        return nil

    end

    local physics =
        tire.wheel.physics

    local originalRadius =
        tonumber(
            tire.originalPhysicsRadius
        )

    if originalRadius == nil
        or originalRadius <= 0 then

        originalRadius =
            tonumber(
                physics.radiusOriginal
            )

    end

    if originalRadius == nil
        or originalRadius <= 0 then

        originalRadius =
            tonumber(
                physics.radius
            )

    end

    if originalRadius == nil
        or originalRadius <= 0 then

        return nil

    end

    tire.originalPhysicsRadius =
        originalRadius

    return originalRadius

end

function TireWear.getProgressiveVisualWear(
    wear
)

    wear =
        TireWear.clamp(
            tonumber(
                wear
            )
            or 0,
            0,
            1
        )

    if wear <= 0 then
        return 0
    end

    return wear
        ^ TireWear.VISUAL_WEAR_EXPONENT

end

function TireWear.updatePhysicalRadius(
    self,
    tire
)
    if not TireWear.isServiceableWheel(tire) then return  end


    if tire == nil
        or tire.wheel == nil
        or tire.wheel.physics == nil then

        return

    end

    if self ~= nil
        and self.isServer == false then

        return

    end

    if tire.visualWearApplied ~= true then
        return
    end

    local physics =
        tire.wheel.physics

    local originalRadius =
        TireWear.getOriginalPhysicsRadius(
            tire
        )

    if originalRadius == nil then
        return
    end

    local targetRadius =
        math.max(
            originalRadius,
            0.05
        )

    local currentRadius =
        tonumber(
            physics.radius
        )
        or originalRadius

    if math.abs(
        currentRadius - targetRadius
    ) < TireWear.PHYSICS_RADIUS_EPSILON then

        tire.currentPhysicsRadius =
            currentRadius

        return

    end

    physics.radius =
        targetRadius

    tire.currentPhysicsRadius =
        targetRadius

    if physics.updateBase ~= nil then

        physics:updateBase()

    end

end

function TireWear.restorePhysicalRadius(
    self,
    tire
)

    if tire == nil
        or tire.wheel == nil
        or tire.wheel.physics == nil then

        return

    end

    if self ~= nil
        and self.isServer == false then

        return

    end

    local physics =
        tire.wheel.physics

    local originalRadius =
        TireWear.getOriginalPhysicsRadius(
            tire
        )

    if originalRadius == nil then
        return
    end

    local currentRadius =
        tonumber(
            physics.radius
        )
        or originalRadius

    if math.abs(
        currentRadius - originalRadius
    ) >= TireWear.PHYSICS_RADIUS_EPSILON then

        physics.radius =
            originalRadius

        if physics.updateBase ~= nil then

            physics:updateBase()

        end

    end

    tire.currentPhysicsRadius =
        originalRadius

end

function TireWear.getLocalGeometryRadius(
    node,
    tireWidth
)

    if node == nil
        or node == 0 then
        return nil
    end

    if getShapeGeometryBoundingSphere == nil then
        return nil
    end

    local centerX,
          centerY,
          centerZ,
          sphereRadius =
        getShapeGeometryBoundingSphere(
            node
        )

    sphereRadius =
        tonumber(
            sphereRadius
        )

    if sphereRadius == nil
        or sphereRadius <= 0.001 then

        return nil

    end

    centerX =
        tonumber(
            centerX
        )
        or 0

    centerY =
        tonumber(
            centerY
        )
        or 0

    centerZ =
        tonumber(
            centerZ
        )
        or 0

    tireWidth =
        tonumber(
            tireWidth
        )
        or 0

    local halfWidth =
        math.max(
            tireWidth * 0.5,
            0
        )

    halfWidth =
        math.min(
            halfWidth,
            sphereRadius * 0.95
        )

    local radialSquared =
        sphereRadius * sphereRadius
        -
        halfWidth * halfWidth

    local radialExtent =
        sphereRadius

    if radialSquared > 0 then

        radialExtent =
            math.sqrt(
                radialSquared
            )

    end

    local centerRadialOffset =
        math.sqrt(
            centerY * centerY
            +
            centerZ * centerZ
        )

    local localOuterRadius =
        radialExtent
        +
        centerRadialOffset

    if localOuterRadius <= 0.001 then

        localOuterRadius =
            sphereRadius

    end

    return localOuterRadius,
           sphereRadius,
           centerX,
           centerY,
           centerZ

end

function TireWear.updateTireNodes(
    self
)

    local spec =
        self.spec_tireWear

    if spec == nil
        or spec.wheels == nil then

        return false

    end

    local allFound =
        true

    for _, tire in ipairs(
        spec.wheels
    ) do

        if tire.tireNode == nil
            or tire.tireNode == 0 then

            local wheel =
                tire.wheel

            if wheel ~= nil
                and wheel.getFirstTireNode ~= nil then

                local node =
                    wheel:getFirstTireNode()

                if node ~= nil
                    and node ~= 0 then

                    tire.tireNode =
                        node

                else

                    allFound =
                        false

                end

            else

                allFound =
                    false

            end

        end

    end

    return allFound

end

function TireWear.captureShaderParameters(
    node
)

    local parameters =
        {}

    if node == nil
        or node == 0 then
        return parameters
    end

    if getNumOfShaderParameters == nil
        or getShaderParameterNameByIndex == nil
        or getShaderParameterByIndex == nil then

        return parameters

    end

    local count =
        getNumOfShaderParameters(
            node,
            0
        )
        or 0

    for index = 0, count - 1 do

        local name =
            getShaderParameterNameByIndex(
                node,
                index,
                0
            )

        if name ~= nil
            and name ~= ""
            and name ~= "realTireWearData" then

            local x,
                  y,
                  z,
                  w =
                getShaderParameterByIndex(
                    node,
                    index,
                    0
                )

            parameters[#parameters + 1] = {
                name = name,
                x = x,
                y = y,
                z = z,
                w = w
            }

        end

    end

    return parameters

end


function TireWear.restoreShaderParameters(
    node,
    parameters
)

    if node == nil
        or node == 0
        or parameters == nil then

        return

    end

    for _, parameter in ipairs(
        parameters
    ) do

        if getHasShaderParameter(
            node,
            parameter.name
        ) then

            setShaderParameter(
                node,
                parameter.name,
                parameter.x,
                parameter.y,
                parameter.z,
                parameter.w,
                false,
                0
            )

        end

    end

end

function TireWear.captureCustomMaps(
    materialId
)

    local maps =
        {}

    if materialId == nil
        or materialId == 0 then
        return maps
    end

    if getMaterialCustomMapFilename == nil then
        return maps
    end

    for _, mapName in ipairs(
        TireWear.CUSTOM_MAP_NAMES
    ) do

        local filename =
            getMaterialCustomMapFilename(
                materialId,
                mapName
            )

        if filename ~= nil
            and filename ~= "" then

            local isSRGB =
                false

            if getMaterialCustomMapIsSRGB ~= nil then

                isSRGB =
                    getMaterialCustomMapIsSRGB(
                        materialId,
                        mapName
                    )
                    == true

            end

            maps[#maps + 1] = {
                name = mapName,
                filename = filename,
                isSRGB = isSRGB
            }

        end

    end

    return maps

end


function TireWear.applyCustomMaps(
    materialId,
    maps,
    sharedEdit
)

    if materialId == nil
        or materialId == 0 then

        return materialId

    end

    if maps == nil
        or setMaterialCustomMapFromFile == nil then

        return materialId

    end

    for _, mapData in ipairs(
        maps
    ) do

        local newMaterialId =
            setMaterialCustomMapFromFile(
                materialId,
                mapData.name,
                mapData.filename,
                true,
                mapData.isSRGB,
                sharedEdit
            )

        if newMaterialId ~= nil
            and newMaterialId ~= 0 then

            materialId =
                newMaterialId

            sharedEdit =
                true

        end

    end

    return materialId

end

function TireWear.captureMaterialCustomParameters(
    materialId
)

    local parameters = {}

    if materialId == nil
        or materialId == 0
        or getMaterialCustomParameter == nil then

        return parameters

    end

    for _, name in ipairs(
        TireWear.MATERIAL_CUSTOM_PARAMETER_NAMES
    ) do

        local x, y, z, w =
            getMaterialCustomParameter(
                materialId,
                name
            )

        if x ~= nil then

            parameters[#parameters + 1] = {
                name = name,
                x = x,
                y = y or 0,
                z = z or 0,
                w = w or 0
            }

        end

    end

    return parameters

end

function TireWear.applyMaterialCustomParameters(
    materialId,
    parameters
)

    if materialId == nil
        or materialId == 0
        or parameters == nil
        or setMaterialCustomParameter == nil then

        return materialId

    end

    local sharedEdit = true

    for _, parameter in ipairs(parameters) do

        local newMaterialId =
            setMaterialCustomParameter(
                materialId,
                parameter.name,
                parameter.x,
                parameter.y,
                parameter.z,
                parameter.w,
                sharedEdit
            )

        if newMaterialId ~= nil
            and newMaterialId ~= 0 then

            materialId = newMaterialId
            sharedEdit = true

        end

    end

    return materialId

end


function TireWear.isMainTireShape(
    node
)

    if node == nil
        or node == 0 then
        return false
    end

    if not getHasClassId(
        node,
        ClassIds.SHAPE
    ) then
        return false
    end


    if getHasShaderParameter(
        node,
        "realTireWearData"
    ) then
        return true
    end

    local materialId =
        getMaterial(
            node,
            0
        )

    if materialId == nil
        or materialId == 0
        or getMaterialCustomShaderVariation == nil then

        return false
    end

    local variation =
        getMaterialCustomShaderVariation(
            materialId
        )
        or ""

    if variation == "tirePressureDeformation"
        or variation == "tirePressureDeformation_vmaskUV2"
        or variation == "tirePressureDeformation_vmaskUV2_normalUV3" then

        return true
    end

    return false

end

function TireWear.createWearMaterial(
    tire,
    node,
    sourceFilename
)

    if not TireWear.isMainTireShape(
        node
    ) then
        return nil
    end

    local originalMaterialId =
        getMaterial(
            node,
            0
        )

    if originalMaterialId == nil
        or originalMaterialId == 0 then

        return nil

    end

    local holderMaterialName =
        TireWear.getCompatibleHolderMaterialName(
            originalMaterialId,
            sourceFilename
        )

    if holderMaterialName == TireWear.T510_MATERIAL_NAME then
        if tire ~= nil and tire.t510OriginalMaterialLogged ~= true then
            Logging.info("[RealTireWear] T510 compatibility: original material retained; visual tread wear disabled | source='%s'", tostring(sourceFilename or ""))
            tire.t510OriginalMaterialLogged = true
        end
        return nil
    end

    local holderMaterialId =
        TireWear.getHolderMaterial(
            holderMaterialName
        )

    if holderMaterialId == nil
        or holderMaterialId == 0 then

        return nil

    end

    local shaderParameters =
        TireWear.captureShaderParameters(
            node
        )

    local materialCustomParameters =
        TireWear.captureMaterialCustomParameters(
            originalMaterialId
        )

    local customMaps =
        TireWear.captureCustomMaps(
            originalMaterialId
        )

    local diffuseFilename =
        nil

    local normalFilename =
        nil

    local glossFilename =
        nil

    if getMaterialDiffuseMapFilename ~= nil then

        diffuseFilename =
            getMaterialDiffuseMapFilename(
                originalMaterialId
            )

    end

    if getMaterialNormalMapFilename ~= nil then

        normalFilename =
            getMaterialNormalMapFilename(
                originalMaterialId
            )

    end

    if getMaterialGlossMapFilename ~= nil then

        glossFilename =
            getMaterialGlossMapFilename(
                originalMaterialId
            )

    end

    local originalVariation =
        ""

    if getMaterialCustomShaderVariation ~= nil then

        originalVariation =
            getMaterialCustomShaderVariation(
                originalMaterialId
            )
            or ""

    end

    local isT510 =
        holderMaterialName == TireWear.T510_MATERIAL_NAME

    local wantedVariation =
        isT510
        and "realTireWearT510"
        or "tirePressureDeformation"

    if string.find(
        originalVariation,
        "normalUV3",
        1,
        true
    ) ~= nil then

        wantedVariation =
            isT510
            and "realTireWearT510_vmaskUV2_normalUV3"
            or "tirePressureDeformation_vmaskUV2_normalUV3"

    elseif string.find(
        originalVariation,
        "vmaskUV2",
        1,
        true
    ) ~= nil
        or string.find(
            originalVariation,
            "secondUV",
            1,
            true
        ) ~= nil then

        wantedVariation =
            isT510
            and "realTireWearT510_vmaskUV2"
            or "tirePressureDeformation_vmaskUV2"

    end

    local materialId =
        setMaterialCustomShaderVariation(
            holderMaterialId,
            wantedVariation,
            false
        )

    if materialId == nil
        or materialId == 0 then

        Logging.warning(
            "[RealTireWear] Private Materialinstanz konnte nicht erzeugt werden"
        )

        return nil

    end

    if diffuseFilename ~= nil
        and diffuseFilename ~= "" then

        local newMaterialId =
            setMaterialDiffuseMapFromFile(
                materialId,
                diffuseFilename,
                true,
                true,
                true
            )

        if newMaterialId ~= nil
            and newMaterialId ~= 0 then

            materialId =
                newMaterialId

        end

    end

    if normalFilename ~= nil
        and normalFilename ~= "" then

        local newMaterialId =
            setMaterialNormalMapFromFile(
                materialId,
                normalFilename,
                true,
                false,
                true
            )

        if newMaterialId ~= nil
            and newMaterialId ~= 0 then

            materialId =
                newMaterialId

        end

    end

    if glossFilename ~= nil
        and glossFilename ~= "" then

        local newMaterialId =
            setMaterialGlossMapFromFile(
                materialId,
                glossFilename,
                true,
                false,
                true
            )

        if newMaterialId ~= nil
            and newMaterialId ~= 0 then

            materialId =
                newMaterialId

        end

    end

    materialId =
        TireWear.applyMaterialCustomParameters(
            materialId,
            materialCustomParameters
        )

    materialId =
        TireWear.applyCustomMaps(
            materialId,
            customMaps,
            true
        )

    if holderMaterialName == TireWear.T510_MATERIAL_NAME
        and tire ~= nil
        and tire.t510MaterialLogged ~= true then

        local originalShader = ""

        if getMaterialCustomShaderFilename ~= nil then
            originalShader =
                getMaterialCustomShaderFilename(
                    originalMaterialId
                )
                or ""
        end

        Logging.info(
            "[RealTireWear] T510 dedicated holder/shader | source='%s' shader='%s' variation='%s' -> '%s' diffuse='%s' normal='%s' gloss='%s'",
            tostring(sourceFilename or ""),
            tostring(originalShader),
            tostring(originalVariation),
            tostring(wantedVariation),
            tostring(diffuseFilename or ""),
            tostring(normalFilename or ""),
            tostring(glossFilename or "")
        )

        tire.t510MaterialLogged = true

    end

    setMaterial(
        node,
        materialId,
        0
    )

    TireWear.restoreShaderParameters(
        node,
        shaderParameters
    )

    return materialId

end


function TireWear.ensureWearMaterial(
    tire,
    node,
    sourceFilename
)

    if tire == nil then
        return false
    end

    if not TireWear.isMainTireShape(
        node
    ) then
        return false
    end

    if tire.realTireWearNodes == nil then

        tire.realTireWearNodes =
            {}

    end

    if tire.realTireWearNodes[node] == true then
        return true
    end

    local materialId =
        TireWear.createWearMaterial(
            tire,
            node,
            sourceFilename
        )

    if materialId == nil then
        return false
    end

    if not getHasShaderParameter(
        node,
        "realTireWearData"
    ) then

        Logging.warning(
            "[RealTireWear] Shape '%s' hat nach Materialwechsel keinen realTireWearData Parameter",
            tostring(
                getName(
                    node
                )
            )
        )

        return false

    end

    tire.realTireWearNodes[node] =
        true

    TireWear.log(
        "RealTireWear-Material auf Hauptshape '%s' gesetzt",
        tostring(
            getName(
                node
            )
        )
    )

    return true

end

function TireWear.applyTreadWearToShape(
    tire,
    node,
    wear,
    sourceFilename
)

    if tire == nil then
        return
    end

    if not TireWear.isMainTireShape(
        node
    ) then
        return
    end

    if not TireWear.ensureWearMaterial(
        tire,
        node,
        sourceFilename
    ) then
        return
    end

    if not getHasShaderParameter(
        node,
        "realTireWearData"
    ) then
        return
    end

    local physicsRadius,
          tireWidth =
        TireWear.getWheelDimensions(
            tire
        )

    local localOuterRadius,
          sphereRadius,
          centerX,
          centerY,
          centerZ =
        TireWear.getLocalGeometryRadius(
            node,
            tireWidth
        )

    if localOuterRadius == nil then

        localOuterRadius =
            physicsRadius

    end

    local maxTreadDepth =
        localOuterRadius
        *
        TireWear.MAX_TREAD_DEPTH_RATIO

    wear =
        TireWear.clamp(
            tonumber(
                wear
            )
            or 0,
            0,
            1
        )

    setShaderParameter(
        node,
        "realTireWearData",
        wear,
        tireWidth,
        localOuterRadius,
        maxTreadDepth,
        false,
        0
    )

    tire.visualWearApplied =
        true

    tire.visualMaxTreadDepth =
        math.max(
            tonumber(
                tire.visualMaxTreadDepth
            )
            or 0,
            maxTreadDepth
        )

    if tire.dimensionLogged ~= true then

        TireWear.log(
            "Profil-Geometrie | PhysRadius=%.3f Breite=%.3f LocalRadius=%.3f ProfilTiefe=%.3f",
            physicsRadius,
            tireWidth,
            localOuterRadius,
            maxTreadDepth
        )

        if sphereRadius ~= nil then

            TireWear.log(
                "BoundingSphere | Radius=%.3f Center=%.3f %.3f %.3f",
                sphereRadius,
                centerX or 0,
                centerY or 0,
                centerZ or 0
            )

        end

        tire.dimensionLogged =
            true

    end

end

function TireWear.applyWearRecursive(
    tire,
    node,
    wear,
    depth
)

    if node == nil
        or node == 0 then
        return
    end

    depth =
        depth or 0

    if depth > 10 then
        return
    end

    if TireWear.isMainTireShape(
        node
    ) then

        TireWear.applyTreadWearToShape(
            tire,
            node,
            wear
        )

        return

    end

    local numChildren =
        getNumOfChildren(
            node
        )
        or 0

    for i = 0, numChildren - 1 do

        local child =
            getChildAt(
                node,
                i
            )

        TireWear.applyWearRecursive(
            tire,
            child,
            wear,
            depth + 1
        )

    end

end


function TireWear.updateVisualWear(
    self,
    index
)

    local spec =
        self.spec_tireWear

    if spec == nil
        or spec.wheels == nil then
        return
    end

    local tire =
        spec.wheels[index]
    if not TireWear.isServiceableWheel(tire) then return end


    if tire == nil then
        return
    end

    local wear =
        TireWear.clamp(
            tonumber(
                tire.wear
            )
            or 0,
            0,
            1
        )

    tire.visualWearApplied =
        false

    tire.visualMaxTreadDepth =
        0

    local applied =
        false

    local wheel =
        tire.wheel

    if wheel ~= nil
        and wheel.visualWheels ~= nil
        and WheelVisualPartTire ~= nil then

        for _, visualWheel in ipairs(
            wheel.visualWheels
        ) do

            if visualWheel ~= nil
                and visualWheel.visualParts ~= nil then

                for _, visualPart in ipairs(
                    visualWheel.visualParts
                ) do

                    local isTirePart =
                        visualPart ~= nil
                        and visualPart.isa ~= nil
                        and visualPart:isa(
                            WheelVisualPartTire
                        )

                    if isTirePart
                        and visualPart.tireNodes ~= nil then

                        for _, node in ipairs(
                            visualPart.tireNodes
                        ) do

                            if TireWear.isMainTireShape(
                                node
                            ) then

                                TireWear.applyTreadWearToShape(
                                    tire,
                                    node,
                                    wear,
                                    visualWheel.externalXMLFilename
                                )

                                applied =
                                    true

                            end

                        end

                    end

                end

            end

        end

    end

    if not applied then

        if tire.tireNode == nil
            or tire.tireNode == 0 then

            TireWear.updateTireNodes(
                self
            )

        end

        local node =
            tire.tireNode

        if node ~= nil
            and node ~= 0 then

            TireWear.applyWearRecursive(
                tire,
                node,
                wear,
                0
            )

        end

    end

    if tire.visualWearApplied == true then

        TireWear.updatePhysicalRadius(
            self,
            tire
        )

    end

end

function TireWear.getWheelPhysicsData(
    tire
)

    if tire == nil
        or tire.wheel == nil then

        return nil

    end

    local wheel =
        tire.wheel

    local physics =
        wheel.physics

    if physics == nil then
        return nil
    end

    local wheelNode =
        wheel.node

    local wheelShape =
        physics.wheelShape

    if wheelShape == nil then

        wheelShape =
            wheel.wheelShape

    end

    if wheelNode == nil
        or wheelNode == 0
        or wheelShape == nil then

        return nil

    end

    return wheel,
           physics,
           wheelNode,
           wheelShape

end

function TireWear.updatePhysicalWear(
    self,
    index
)

    if self == nil
        or not self.isServer then

        return

    end

    if self.isAddedToPhysics == false then
        return
    end

    if setWheelShapeTireFriction == nil then
        return
    end

    local spec =
        self.spec_tireWear

    if spec == nil
        or spec.wheels == nil then

        return

    end

    local tire =
        spec.wheels[index]
    if not TireWear.isServiceableWheel(tire) then return end


    if tire == nil
        or tire.wheel == nil then

        return

    end

    local wheel,
          physics,
          wheelNode,
          wheelShape =
        TireWear.getWheelPhysicsData(
            tire
        )

    if wheel == nil then
        return
    end


    local maxLongStiffness =
        tonumber(
            TireWear.getWheelPhysicsValue(
                tire,
                "maxLongStiffness",
                nil
            )
        )

    local maxLatStiffness =
        tonumber(
            TireWear.getWheelPhysicsValue(
                tire,
                "maxLatStiffness",
                nil
            )
        )

    local maxLatStiffnessLoad =
        tonumber(
            TireWear.getWheelPhysicsValue(
                tire,
                "maxLatStiffnessLoad",
                nil
            )
        )

    local frictionScale =
        tonumber(
            TireWear.getWheelPhysicsValue(
                tire,
                "frictionScale",
                nil
            )
        )

    local tireGroundFrictionCoeff =
        tonumber(
            TireWear.getWheelPhysicsValue(
                tire,
                "tireGroundFrictionCoeff",
                nil
            )
        )


    if maxLongStiffness == nil
        or maxLatStiffness == nil
        or maxLatStiffnessLoad == nil
        or frictionScale == nil
        or tireGroundFrictionCoeff == nil then

        if tire.physicsValuesWarningShown ~= true then

            tire.physicsValuesWarningShown =
                true

            Logging.warning(
                "[RealTireWear] Reifen %d: Physikwerte fuer Grip-Anwendung fehlen",
                index
            )

        end

        return

    end


    local sinkFrictionScaleFactor =
        tonumber(
            TireWear.getWheelPhysicsValue(
                tire,
                "sinkFrictionScaleFactor",
                1
            )
        )
        or 1

    local sinkLatStiffnessFactor =
        tonumber(
            TireWear.getWheelPhysicsValue(
                tire,
                "sinkLatStiffnessFactor",
                1
            )
        )
        or 1


    local wearGrip =
        TireWear.clamp(
            tonumber(
                tire.grip
            )
            or 1,
            0.05,
            1
        )


    local finalLongStiffness =
        maxLongStiffness
        *
        sinkFrictionScaleFactor

    local finalLatStiffness =
        maxLatStiffness
        *
        sinkLatStiffnessFactor

    local originalFrictionMultiplier =
        frictionScale
        *
        tireGroundFrictionCoeff
        *
        sinkFrictionScaleFactor

    local finalFrictionMultiplier =
        originalFrictionMultiplier
        *
        wearGrip


    setWheelShapeTireFriction(
        wheelNode,
        wheelShape,
        finalLongStiffness,
        finalLatStiffness,
        maxLatStiffnessLoad,
        finalFrictionMultiplier
    )


    tire.originalFrictionMultiplier =
        originalFrictionMultiplier

    tire.finalFrictionMultiplier =
        finalFrictionMultiplier

    tire.physicsGripApplied =
        wearGrip

end

function TireWear.hasWheelGroundContact(
    tire
)

    if tire == nil
        or tire.wheel == nil
        or tire.wheel.physics == nil then

        return true

    end

    local hasGroundContact =
        tire.wheel.physics.hasGroundContact

    if hasGroundContact == true then
        return true
    end

    local wheel,
          physics,
          wheelNode,
          wheelShape =
        TireWear.getWheelPhysicsData(
            tire
        )

    if wheelNode ~= nil
        and wheelShape ~= nil
        and getWheelShapeContactForce ~= nil then

        local contactForce =
            tonumber(
                getWheelShapeContactForce(
                    wheelNode,
                    wheelShape
                )
            )

        if contactForce ~= nil
            and contactForce > 0.001 then

            return true

        end

    end

    if tire.owner ~= nil then

        local owner =
            tire.owner

        if owner.getRootVehicle ~= nil then

            local rootVehicle =
                owner:getRootVehicle()

            if rootVehicle ~= nil
                and rootVehicle ~= owner then

                return true

            end

        end

    end

    if hasGroundContact == nil then
        return true
    end

    return false

end

function TireWear.getWheelSlip(
    tire
)

    local wheel,
          physics,
          wheelNode,
          wheelShape =
        TireWear.getWheelPhysicsData(
            tire
        )

    if wheel == nil
        or getWheelShapeSlip == nil then

        return 0,
               0,
               0

    end

    if physics.hasGroundContact == false then

        return 0,
               0,
               0

    end

    local longitudinalSlip,
          lateralSlip =
        getWheelShapeSlip(
            wheelNode,
            wheelShape
        )

    longitudinalSlip =
        math.abs(
            tonumber(
                longitudinalSlip
            )
            or 0
        )

    lateralSlip =
        math.abs(
            tonumber(
                lateralSlip
            )
            or 0
        )

    local weightedLateralSlip =
        lateralSlip
        *
        TireWear.LATERAL_SLIP_WEIGHT

    local effectiveSlip =
        math.max(
            longitudinalSlip,
            weightedLateralSlip
        )

    effectiveSlip =
        TireWear.clamp(
            effectiveSlip,
            0,
            2
        )

    return effectiveSlip,
           longitudinalSlip,
           lateralSlip

end


function TireWear.getSlipFactor(
    slip
)

    slip =
        math.max(
            tonumber(
                slip
            )
            or 0,
            0
        )

    if slip <= 0.20 then

        return 1.00

    end

    if slip <= 0.30 then

        local t =
            (
                slip
                -
                0.20
            )
            /
            0.10

        return TireWear.lerp(
            1.00,
            1.10,
            t
        )

    end

    if slip <= 0.50 then

        local t =
            (
                slip
                -
                0.30
            )
            /
            0.20

        return TireWear.lerp(
            1.10,
            1.35,
            t
        )

    end

    if slip <= 0.75 then

        local t =
            (
                slip
                -
                0.50
            )
            /
            0.25

        return TireWear.lerp(
            1.35,
            1.75,
            t
        )

    end

    if slip <= 1.00 then

        local t =
            (
                slip
                -
                0.75
            )
            /
            0.25

        return TireWear.lerp(
            1.75,
            TireWear.MAX_SLIP_FACTOR,
            t
        )

    end

    return TireWear.MAX_SLIP_FACTOR

end

function TireWear.getWheelContactForce(
    tire
)

    local wheel,
          physics,
          wheelNode,
          wheelShape =
        TireWear.getWheelPhysicsData(
            tire
        )

    if wheel == nil
        or getWheelShapeContactForce == nil then

        return nil

    end

    if physics.hasGroundContact == false then
        return 0
    end

    local force =
        getWheelShapeContactForce(
            wheelNode,
            wheelShape
        )

    force =
        tonumber(
            force
        )

    if force == nil then
        return nil
    end

    return math.max(
        force,
        0
    )

end


function TireWear.getAverageContactForce(
    spec
)

    if spec == nil
        or spec.wheels == nil then

        return nil

    end

    local forceSum =
        0

    local forceCount =
        0

    for _, tire in ipairs(
        spec.wheels
    ) do

        if TireWear.isServiceableWheel(tire) and TireWear.hasWheelGroundContact(
            tire
        ) then

            local force =
                TireWear.getWheelContactForce(
                    tire
                )

            if force ~= nil
                and force > 0 then

                forceSum =
                    forceSum
                    +
                    force

                forceCount =
                    forceCount
                    +
                    1

            end

        end

    end

    if forceCount == 0 then
        return nil
    end

    return forceSum
        /
        forceCount

end


function TireWear.getLoadFactor(
    contactForce,
    averageContactForce
)

    if contactForce == nil
        or averageContactForce == nil
        or averageContactForce <= 0 then

        return 1

    end

    local loadRatio =
        contactForce
        /
        averageContactForce

    local factor =
        0.65
        +
        (
            loadRatio
            *
            0.35
        )

    return TireWear.clamp(
        factor,
        TireWear.MIN_LOAD_FACTOR,
        TireWear.MAX_LOAD_FACTOR
    )

end

function TireWear.getVehicleSpeedKmh(
    self
)

    if self.getLastSpeed ~= nil then

        local speed =
            tonumber(
                self:getLastSpeed(
                    true
                )
            )

        if speed ~= nil then

            return math.abs(
                speed
            )

        end

    end

    if self.lastSpeedReal ~= nil then

        return math.abs(
            self.lastSpeedReal
            *
            3600
        )

    end

    return 0

end


function TireWear.getSpeedFactor(
    speedKmh
)

    speedKmh =
        math.max(
            tonumber(
                speedKmh
            )
            or 0,
            0
        )

    if speedKmh <= 10 then
        return 1
    end

    local normalized =
        TireWear.clamp(
            (
                speedKmh
                -
                10
            )
            /
            40,
            0,
            1
        )

    return 1
        +
        (
            normalized
            *
            (
                TireWear.MAX_SPEED_FACTOR
                -
                1
            )
        )

end

function TireWear.getGroundData(
    tire
)

    if tire == nil
        or tire.wheel == nil
        or tire.wheel.physics == nil then

        return 0,
               false,
               nil

    end

    local physics =
        tire.wheel.physics

    local groundDepth =
        tonumber(
            physics.groundDepth
        )

    local hasSoilContact =
        physics.hasSoilContact
        == true

    local terrainAttribute =
        tonumber(
            physics.lastTerrainAttribute
        )

    if groundDepth == nil
        and physics.getGroundAttributes ~= nil then

        local r,
              g,
              b,
              depth =
            physics:getGroundAttributes()

        groundDepth =
            tonumber(
                depth
            )

    end

    groundDepth =
        math.max(
            groundDepth or 0,
            0
        )

    return groundDepth,
           hasSoilContact,
           terrainAttribute

end


function TireWear.getGroundFactor(
    tire
)

    if not TireWear.hasWheelGroundContact(
        tire
    ) then

        return 0,
               "AIR",
               0

    end

    local groundDepth,
          hasSoilContact,
          terrainAttribute =
        TireWear.getGroundData(
            tire
        )

    if hasSoilContact then

        return TireWear.GROUND_FACTOR_FIELD,
               "FIELD",
               groundDepth

    end

    if groundDepth <= 0.10 then

        return TireWear.GROUND_FACTOR_ROAD,
               "ROAD",
               groundDepth

    end

    if groundDepth > 0.80 then

        return TireWear.GROUND_FACTOR_SOFT,
               "SOFT",
               groundDepth

    end

    return TireWear.GROUND_FACTOR_HARD,
           "HARD",
           groundDepth

end

function TireWear.calculateWheelWearFactor(
    tire,
    averageContactForce,
    speedFactor
)
    if not TireWear.isServiceableWheel(tire) then return 0 end


    if tire == nil then
        return 0
    end

    if not TireWear.hasWheelGroundContact(
        tire
    ) then

        tire.slip =
            0

        tire.longitudinalSlip =
            0

        tire.lateralSlip =
            0

        tire.contactForce =
            0

        tire.slipFactor =
            0

        tire.loadFactor =
            0

        tire.speedFactor =
            speedFactor

        tire.groundFactor =
            0

        tire.groundDepth =
            0

        tire.groundType =
            "AIR"

        tire.wearFactor =
            0

        return 0

    end

    local effectiveSlip,
          longitudinalSlip,
          lateralSlip =
        TireWear.getWheelSlip(
            tire
        )

    local slipFactor =
        TireWear.getSlipFactor(
            effectiveSlip
        )

    local contactForce =
        TireWear.getWheelContactForce(
            tire
        )

    local loadFactor =
        TireWear.getLoadFactor(
            contactForce,
            averageContactForce
        )

    local groundFactor,
          groundType,
          groundDepth =
        TireWear.getGroundFactor(
            tire
        )

    local totalFactor =
        slipFactor
        *
        loadFactor
        *
        speedFactor
        *
        groundFactor

    totalFactor =
        TireWear.clamp(
            totalFactor,
            0,
            TireWear.MAX_TOTAL_WEAR_FACTOR
        )

    tire.slip =
        effectiveSlip

    tire.longitudinalSlip =
        longitudinalSlip

    tire.lateralSlip =
        lateralSlip

    tire.contactForce =
        contactForce
        or 0

    tire.slipFactor =
        slipFactor

    tire.loadFactor =
        loadFactor

    tire.speedFactor =
        speedFactor

    tire.groundFactor =
        groundFactor

    tire.groundDepth =
        groundDepth

    tire.groundType =
        groundType

    tire.wearFactor =
        totalFactor

    return totalFactor

end

function TireWear.updateGrip(
    tire
)
    if not TireWear.isServiceableWheel(tire) then return  end


    if tire == nil then
        return
    end

    local wear =
        TireWear.clamp(
            tonumber(
                tire.wear
            )
            or 0,
            0,
            1
        )

    tire.wear =
        wear

    if wear <= 0.70 then

        local t =
            wear
            /
            0.70

        tire.grip =
            TireWear.lerp(
                TireWear.GRIP_NEW,
                TireWear.GRIP_WORN,
                t
            )

        return

    end

    if wear <= 0.90 then

        local t =
            (
                wear
                -
                0.70
            )
            /
            0.20

        tire.grip =
            TireWear.lerp(
                TireWear.GRIP_WORN,
                TireWear.GRIP_CRITICAL,
                t
            )

        return

    end

    local t =
        (
            wear
            -
            0.90
        )
        /
        0.10

    tire.grip =
        TireWear.lerp(
            TireWear.GRIP_CRITICAL,
            TireWear.GRIP_FULLY_WORN,
            t
        )

end

TireWear.CRAWLER_MATERIAL_HOLDER_FILENAME =
    Utils.getFilename(
        "materialHolder/crawlerMaterialHolder.i3d",
        g_currentModDirectory
    )

TireWear.CRAWLER_PROFILE_BODY_Y = 0.020
TireWear.CRAWLER_PROFILE_OUTER_Y = 0.087339
TireWear.TRACK_VISUAL_UPDATE_MS = 200
TireWear.crawlerMaterialLoaded = false
TireWear.crawlerMaterialHolderNode = nil
TireWear.trackBaseMaterialId = nil
TireWear.trackMaterialCache = {}
TireWear.trackWearMaterialSlots = {}

function TireWear.loadCrawlerMaterial()
    if TireWear.crawlerMaterialLoaded == true then
        return TireWear.trackBaseMaterialId ~= nil
    end

    TireWear.crawlerMaterialLoaded = true

    if g_i3DManager == nil
        or g_i3DManager.loadSharedI3DFile == nil then
        return false
    end

    local nodeId =
        g_i3DManager:loadSharedI3DFile(
            TireWear.CRAWLER_MATERIAL_HOLDER_FILENAME,
            false,
            false
        )

    if nodeId == nil or nodeId == 0 then
        Logging.warning(
            "[RealTireWear] Crawler-MaterialHolder konnte nicht geladen werden: %s",
            tostring(TireWear.CRAWLER_MATERIAL_HOLDER_FILENAME)
        )
        return false
    end

    TireWear.crawlerMaterialHolderNode = nodeId

    local materialNode =
        I3DUtil.indexToObject(
            nodeId,
            "0|0"
        )

    if materialNode == nil or materialNode == 0 then
        Logging.warning(
            "[RealTireWear] Crawler-MaterialHolder hat keinen Material-Node"
        )
        return false
    end

    TireWear.trackBaseMaterialId =
        getMaterial(
            materialNode,
            0
        )

    return TireWear.trackBaseMaterialId ~= nil
        and TireWear.trackBaseMaterialId ~= 0
end

function TireWear.copyTrackCustomMap(
    materialId,
    originalMaterialId,
    mapName,
    isSRGB
)
    if materialId == nil
        or materialId == 0
        or originalMaterialId == nil
        or originalMaterialId == 0
        or getMaterialCustomMapFilename == nil
        or setMaterialCustomMapFromFile == nil then

        return materialId
    end

    local okFilename,
          filename =
        pcall(
            getMaterialCustomMapFilename,
            originalMaterialId,
            mapName
        )

    if not okFilename
        or filename == nil
        or filename == "" then

        return materialId
    end

    local okSet,
          newMaterialId =
        pcall(
            setMaterialCustomMapFromFile,
            materialId,
            mapName,
            filename,
            false,
            isSRGB == true,
            false
        )

    if okSet
        and newMaterialId ~= nil
        and newMaterialId ~= 0 then

        return newMaterialId
    end

    return materialId
end

function TireWear.buildTrackWearMaterial(
    originalMaterialId,
    variation
)
    if originalMaterialId == nil
        or originalMaterialId == 0
        or not TireWear.loadCrawlerMaterial() then

        return nil
    end

    local cacheKey =
        tostring(originalMaterialId)
        .. "|"
        .. tostring(variation or "motionPathRubber_vmaskUV2")

    local cached =
        TireWear.trackMaterialCache[cacheKey]

    if cached ~= nil and cached ~= 0 then
        return cached
    end

    local materialId =
        TireWear.trackBaseMaterialId

    if getMaterialDiffuseMapFilename ~= nil
        and setMaterialDiffuseMapFromFile ~= nil then

        local ok,
              filename =
            pcall(
                getMaterialDiffuseMapFilename,
                originalMaterialId
            )

        if ok
            and filename ~= nil
            and filename ~= "" then

            local okSet,
                  newMaterialId =
                pcall(
                    setMaterialDiffuseMapFromFile,
                    materialId,
                    filename,
                    false,
                    true,
                    false
                )

            if okSet
                and newMaterialId ~= nil
                and newMaterialId ~= 0 then

                materialId = newMaterialId
            end
        end
    end

    if getMaterialNormalMapFilename ~= nil
        and setMaterialNormalMapFromFile ~= nil then

        local ok,
              filename =
            pcall(
                getMaterialNormalMapFilename,
                originalMaterialId
            )

        if ok
            and filename ~= nil
            and filename ~= "" then

            local okSet,
                  newMaterialId =
                pcall(
                    setMaterialNormalMapFromFile,
                    materialId,
                    filename,
                    false,
                    false,
                    false
                )

            if okSet
                and newMaterialId ~= nil
                and newMaterialId ~= 0 then

                materialId = newMaterialId
            end
        end
    end

    if getMaterialGlossMapFilename ~= nil
        and setMaterialGlossMapFromFile ~= nil then

        local ok,
              filename =
            pcall(
                getMaterialGlossMapFilename,
                originalMaterialId
            )

        if ok
            and filename ~= nil
            and filename ~= "" then

            local okSet,
                  newMaterialId =
                pcall(
                    setMaterialGlossMapFromFile,
                    materialId,
                    filename,
                    false,
                    false,
                    false
                )

            if okSet
                and newMaterialId ~= nil
                and newMaterialId ~= 0 then

                materialId = newMaterialId
            end
        end
    end

    for _, mapData in ipairs({
        {"detailSpecular", false},
        {"detailNormal", false},
        {"detailDiffuse", true},
        {"dirtSpecular", false},
        {"dirtNormal", false},
        {"dirtDiffuse", true},
        {"waterDroplets", false},
        {"trackArray", false}
    }) do
        materialId =
            TireWear.copyTrackCustomMap(
                materialId,
                originalMaterialId,
                mapData[1],
                mapData[2]
            )
    end

    if setMaterialCustomShaderVariation ~= nil then
        local targetVariation =
            variation == "motionPathRubber"
            and "motionPathRubber"
            or "motionPathRubber_vmaskUV2"

        local okSet,
              newMaterialId =
            pcall(
                setMaterialCustomShaderVariation,
                materialId,
                targetVariation,
                false
            )

        if okSet
            and newMaterialId ~= nil
            and newMaterialId ~= 0 then

            materialId = newMaterialId
        end
    end

    TireWear.trackMaterialCache[cacheKey] = materialId

    return materialId
end

function TireWear.captureTrackShaderParameters(
    node,
    materialIndex
)
    local result = {}

    if node == nil or node == 0 then
        return result
    end

    materialIndex = materialIndex or 0

    if getNumOfShaderParameters ~= nil
        and getShaderParameterNameByIndex ~= nil
        and getShaderParameterByIndex ~= nil then

        local okCount,
              count =
            pcall(
                getNumOfShaderParameters,
                node,
                materialIndex
            )

        count = okCount and tonumber(count) or 0

        if count ~= nil and count > 0 then
            for index = 0, count - 1 do
                local okName,
                      name =
                    pcall(
                        getShaderParameterNameByIndex,
                        node,
                        index,
                        materialIndex
                    )

                if okName
                    and name ~= nil
                    and name ~= ""
                    and name ~= "realCrawlerWearData" then

                    local okValue,
                          x,
                          y,
                          z,
                          w =
                        pcall(
                            getShaderParameterByIndex,
                            node,
                            index,
                            materialIndex
                        )

                    if okValue then
                        result[#result + 1] = {
                            name = name,
                            x = x,
                            y = y,
                            z = z,
                            w = w
                        }
                    end
                end
            end

            return result
        end
    end

    for _, name in ipairs({
        "scratches_dirt_snow_wetness",
        "dirtColor",
        "colorScale",
        "smoothnessScale",
        "metalnessScale",
        "clearCoatIntensity",
        "clearCoatSmoothness",
        "porosity",
        "scrollPos",
        "prevScrollPos",
        "lengthAndRadius",
        "ssrParameters"
    }) do
        local okHas,
              hasParameter =
            pcall(
                getHasShaderParameter,
                node,
                name,
                materialIndex
            )

        if okHas and hasParameter then
            local okGet,
                  x,
                  y,
                  z,
                  w =
                pcall(
                    getShaderParameter,
                    node,
                    name,
                    materialIndex
                )

            if okGet then
                result[#result + 1] = {
                    name = name,
                    x = x,
                    y = y,
                    z = z,
                    w = w
                }
            end
        end
    end

    return result
end

function TireWear.restoreTrackShaderParameters(
    node,
    materialIndex,
    parameters
)
    if node == nil
        or node == 0
        or parameters == nil then

        return
    end

    materialIndex = materialIndex or 0

    for _, parameter in ipairs(parameters) do
        local okHas,
              hasParameter =
            pcall(
                getHasShaderParameter,
                node,
                parameter.name,
                materialIndex
            )

        if okHas and hasParameter then
            pcall(
                setShaderParameter,
                node,
                parameter.name,
                parameter.x,
                parameter.y,
                parameter.z,
                parameter.w,
                false,
                materialIndex
            )
        end
    end
end

function TireWear.getTrackMaterialCandidates(
    node
)
    local result = {}

    if node == nil or node == 0 then
        return result
    end

    if getHasClassId ~= nil
        and ClassIds ~= nil
        and ClassIds.SHAPE ~= nil then

        local okShape, isShape =
            pcall(
                getHasClassId,
                node,
                ClassIds.SHAPE
            )

        if not okShape or isShape ~= true then
            return result
        end
    end

    local okCount,
          materialCount =
        pcall(
            getNumOfMaterials,
            node
        )

    materialCount =
        okCount
        and tonumber(materialCount)
        or 0

    if materialCount == nil or materialCount <= 0 then
        materialCount = 1
    end

    for materialIndex = 0, materialCount - 1 do
        local okMaterial,
              materialId =
            pcall(
                getMaterial,
                node,
                materialIndex
            )

        if okMaterial
            and materialId ~= nil
            and materialId ~= 0 then

            local variation = nil

            if getMaterialCustomShaderVariation ~= nil then
                local okVariation,
                      value =
                    pcall(
                        getMaterialCustomShaderVariation,
                        materialId
                    )

                if okVariation then
                    variation = value
                end
            end

            local okWear,
                  hasWearParameter =
                pcall(
                    getHasShaderParameter,
                    node,
                    "realCrawlerWearData",
                    materialIndex
                )

            hasWearParameter =
                okWear
                and hasWearParameter == true

            local isRubberMotionPath =
                variation == "motionPathRubber"
                or variation == "motionPathRubber_vmaskUV2"

            if hasWearParameter or isRubberMotionPath then
                result[#result + 1] = {
                    materialIndex = materialIndex,
                    materialId = materialId,
                    variation = variation,
                    hasWearParameter = hasWearParameter,
                    isRubberMotionPath = isRubberMotionPath
                }
            end
        end
    end

    return result
end

function TireWear.getCrawlerTrackShapes(
    crawler
)
    local result = {}
    local seen = {}

    if crawler == nil then
        return result
    end

    local function addNode(node)
        if node == nil or node == 0 then
            return
        end

        local candidates =
            TireWear.getTrackMaterialCandidates(
                node
            )

        for _, candidate in ipairs(candidates) do
            if candidate.isRubberMotionPath
                or candidate.hasWearParameter then

                local key =
                    tostring(node)
                    .. ":"
                    .. tostring(candidate.materialIndex)

                if seen[key] ~= true then
                    seen[key] = true

                    result[#result + 1] = {
                        node = node,
                        materialIndex = candidate.materialIndex
                    }
                end
            end
        end
    end

    for _, entry in ipairs(crawler.scrollerNodes or {}) do
        if entry ~= nil then
            addNode(entry.node)

            for _, node in ipairs(entry.nodes or {}) do
                addNode(node)
            end
        end
    end

    local root = crawler.loadedCrawler

    if root ~= nil
        and root ~= 0
        and I3DUtil ~= nil
        and I3DUtil.iterateRecursively ~= nil then

        pcall(
            I3DUtil.iterateRecursively,
            root,
            addNode
        )
    end

    return result
end

function TireWear.findTireByWheel(
    spec,
    wheel
)
    if spec == nil
        or spec.wheels == nil
        or wheel == nil then

        return nil
    end

    for _, tire in ipairs(spec.wheels) do
        if tire ~= nil and tire.wheel == wheel then
            return tire
        end
    end

    return nil
end

function TireWear.getCrawlerMemberTires(
    self,
    crawler,
    crawlerIndex
)
    local result = {}
    local seen = {}
    local spec = self.spec_tireWear

    if spec == nil
        or spec.wheels == nil
        or crawler == nil then

        return result
    end

    local function addTire(tire)
        if tire ~= nil and seen[tire] ~= true then
            seen[tire] = true
            result[#result + 1] = tire
        end
    end

    for _, wheelData in pairs(crawler.wheels or {}) do
        local wheel =
            type(wheelData) == "table"
            and (wheelData.wheel or wheelData)
            or wheelData

        addTire(
            TireWear.findTireByWheel(
                spec,
                wheel
            )
        )
    end

    for _, wheelIndex in pairs(crawler.wheelIndices or {}) do
        local numericIndex = tonumber(wheelIndex)

        if numericIndex ~= nil then
            addTire(
                spec.wheels[numericIndex]
                or spec.wheels[numericIndex + 1]
            )
        end
    end

    for _, wheelNode in pairs(crawler.wheelNodes or {}) do
        for _, tire in ipairs(spec.wheels) do
            local wheel = tire ~= nil and tire.wheel or nil

            if wheel ~= nil
                and (
                    wheel.repr == wheelNode
                    or wheel.driveNode == wheelNode
                    or wheel.linkNode == wheelNode
                ) then

                addTire(tire)
            end
        end
    end

    if #result == 0
        and self.rootNode ~= nil
        and crawler.linkNode ~= nil
        and crawler.linkNode ~= 0
        and localToLocal ~= nil
        and self.spec_crawlers ~= nil
        and self.spec_crawlers.crawlers ~= nil then

        for _, tire in ipairs(spec.wheels) do
            if tire ~= nil
                and tire.wheel ~= nil
                and TireReplaceEvent.isCrawlerWheel(tire) then

                local wheelNode =
                    tire.wheel.repr
                    or tire.wheel.driveNode

                if wheelNode ~= nil and wheelNode ~= 0 then
                    local okWheel,
                          wx,
                          _,
                          wz =
                        pcall(
                            localToLocal,
                            wheelNode,
                            self.rootNode,
                            0,
                            0,
                            0
                        )

                    if okWheel and wx ~= nil and wz ~= nil then
                        local bestCrawler = nil
                        local bestDistance = math.huge

                        for candidateIndex, candidateCrawler in ipairs(self.spec_crawlers.crawlers) do
                            if candidateCrawler ~= nil
                                and candidateCrawler.linkNode ~= nil
                                and candidateCrawler.linkNode ~= 0 then

                                local okCrawler,
                                      cx,
                                      _,
                                      cz =
                                    pcall(
                                        localToLocal,
                                        candidateCrawler.linkNode,
                                        self.rootNode,
                                        0,
                                        0,
                                        0
                                    )

                                if okCrawler and cx ~= nil and cz ~= nil then
                                    local dx = wx - cx
                                    local dz = wz - cz
                                    local distance = dx * dx + dz * dz

                                    if distance < bestDistance then
                                        bestDistance = distance
                                        bestCrawler = candidateIndex
                                    end
                                end
                            end
                        end

                        if bestCrawler == crawlerIndex then
                            addTire(tire)
                        end
                    end
                end
            end
        end
    end

    if #result == 0
        and TireReplaceEvent.isCrawlerServiceVehicle(self) then

        local firstIndex =
            (math.max(tonumber(crawlerIndex) or 1, 1) - 1)
            * 2
            + 1

        addTire(spec.wheels[firstIndex])
        addTire(spec.wheels[firstIndex + 1])
    end

    if #result == 0 then
        local sideKnown = crawler.isLeft ~= nil

        for _, tire in ipairs(spec.wheels) do
            if TireReplaceEvent.isCrawlerWheel(tire) then
                local wheel = tire.wheel

                if not sideKnown
                    or wheel == nil
                    or wheel.isLeft == nil
                    or wheel.isLeft == crawler.isLeft then

                    addTire(tire)
                end
            end
        end
    end

    return result
end

function TireWear.getCrawlerVisualWear(
    self,
    crawler,
    crawlerIndex
)
    local tires =
        TireWear.getCrawlerMemberTires(
            self,
            crawler,
            crawlerIndex
        )

    if #tires == 0 then
        return 0
    end

    local wearSum = 0
    local wearCount = 0

    for _, tire in ipairs(tires) do
        if tire ~= nil then
            wearSum =
                wearSum
                + TireWear.clamp(
                    tonumber(tire.wear) or 0,
                    0,
                    1
                )

            wearCount = wearCount + 1
        end
    end

    if wearCount == 0 then
        return 0
    end

    return TireWear.clamp(
        wearSum / wearCount,
        0,
        1
    )
end

function TireWear.ensureTrackWearMaterial(
    node,
    materialIndex
)
    if node == nil or node == 0 then
        return false
    end

    materialIndex = materialIndex or 0

    local okMaterial,
          currentMaterial =
        pcall(
            getMaterial,
            node,
            materialIndex
        )

    if not okMaterial
        or currentMaterial == nil
        or currentMaterial == 0 then

        return false
    end

    local okWear,
          hasWearParameter =
        pcall(
            getHasShaderParameter,
            node,
            "realCrawlerWearData",
            materialIndex
        )

    if okWear and hasWearParameter then
        return true
    end

    local variation = nil

    if getMaterialCustomShaderVariation ~= nil then
        local okVariation,
              value =
            pcall(
                getMaterialCustomShaderVariation,
                currentMaterial
            )

        if okVariation then
            variation = value
        end
    end

    if variation ~= "motionPathRubber"
        and variation ~= "motionPathRubber_vmaskUV2" then

        return false
    end

    local nodeSlots =
        TireWear.trackWearMaterialSlots[node]

    if nodeSlots == nil then
        nodeSlots = {}
        TireWear.trackWearMaterialSlots[node] = nodeSlots
    end

    local slotState = nodeSlots[materialIndex]

    if slotState ~= nil
        and slotState.materialId == currentMaterial then

        local okExisting,
              existingHasWear =
            pcall(
                getHasShaderParameter,
                node,
                "realCrawlerWearData",
                materialIndex
            )

        return okExisting and existingHasWear == true
    end

    local parameters =
        TireWear.captureTrackShaderParameters(
            node,
            materialIndex
        )

    local wearMaterial =
        TireWear.buildTrackWearMaterial(
            currentMaterial,
            variation
        )

    if wearMaterial == nil
        or wearMaterial == 0 then

        return false
    end

    local okSet =
        pcall(
            setMaterial,
            node,
            wearMaterial,
            materialIndex
        )

    if not okSet then
        return false
    end

    TireWear.restoreTrackShaderParameters(
        node,
        materialIndex,
        parameters
    )

    nodeSlots[materialIndex] = {
        originalMaterialId = currentMaterial,
        materialId = wearMaterial,
        variation = variation
    }

    local okFinal,
          finalHasWear =
        pcall(
            getHasShaderParameter,
            node,
            "realCrawlerWearData",
            materialIndex
        )

    return okFinal and finalHasWear == true
end

function TireWear.applyCrawlerTrackWear(
    node,
    materialIndex,
    wear
)
    if not TireWear.ensureTrackWearMaterial(
        node,
        materialIndex
    ) then
        return false
    end

    wear =
        TireWear.clamp(
            tonumber(wear) or 0,
            0,
            1
        )

    local nodeName = ""

    if getName ~= nil then
        local okName,
              value =
            pcall(
                getName,
                node
            )

        if okName and value ~= nil then
            nodeName = string.lower(tostring(value))
        end
    end
	
    local positiveOuterSide =
        string.find(nodeName, "trion", 1, true) ~= nil
        or string.find(nodeName, "terratrac", 1, true) ~= nil
        or string.find(nodeName, "terra_trac", 1, true) ~= nil

    local outerSide = positiveOuterSide and 1 or -1

    local okSet =
        pcall(
            setShaderParameter,
            node,
            "realCrawlerWearData",
            wear,
            TireWear.CRAWLER_PROFILE_BODY_Y,
            TireWear.CRAWLER_PROFILE_OUTER_Y,
            outerSide,
            false,
            materialIndex
        )

    return okSet
end

function TireWear.updateCrawlerVisualWear(
    self,
    dt
)
    if self == nil
        or self.spec_tireWear == nil
        or self.spec_crawlers == nil
        or self.spec_crawlers.crawlers == nil
        or #self.spec_crawlers.crawlers == 0 then

        return
    end

    local spec = self.spec_tireWear

    spec.trackVisualUpdateTimer =
        (spec.trackVisualUpdateTimer or TireWear.TRACK_VISUAL_UPDATE_MS)
        + math.max(tonumber(dt) or 0, 0)

    if spec.trackVisualUpdateTimer
        < TireWear.TRACK_VISUAL_UPDATE_MS then

        return
    end

    spec.trackVisualUpdateTimer = 0
    spec.trackVisualShapeCache =
        spec.trackVisualShapeCache
        or setmetatable({}, {__mode = "k"})

    for crawlerIndex, crawler in ipairs(self.spec_crawlers.crawlers) do
        local wear =
            TireWear.getCrawlerVisualWear(
                self,
                crawler,
                crawlerIndex
            )

        local shapes =
            spec.trackVisualShapeCache[crawler]

        if shapes == nil or #shapes == 0 then
            shapes =
                TireWear.getCrawlerTrackShapes(
                    crawler
                )

            if #shapes > 0 then
                spec.trackVisualShapeCache[crawler] = shapes
            end
        end

        for _, shape in ipairs(shapes or {}) do
            TireWear.applyCrawlerTrackWear(
                shape.node,
                shape.materialIndex,
                wear
            )
        end
    end
end


TireWear.AIR_LOSS_MS = 8000
TireWear.PUNCTURE_CHANCE_PERCENT = 0.1
TireWear.PUNCTURE_CHECK_MS = 60000
TireWear.FLAT_SPEED_LIMIT = 15
TireWear.AIR_LOSS_RADIUS_RATIO = 0.12
TireWear.AIR_SOUND = Utils.getFilename("sounds/tireAirLeak.ogg", g_currentModDirectory)

function TireWear.stopAirSound(tire)
    if tire.airSource ~= nil then
        delete(tire.airSource)
        tire.airSource = nil
    end
end

function TireWear.setAirDamage(vehicle, tire, damaged, silent)
    damaged = damaged == true
    if damaged and not tire.damaged then
        tire.airLoss = silent and 1 or 0
        if not silent and vehicle.isClient and vehicle.rootNode ~= nil then
            TireWear.stopAirSound(tire)
            local node = tire.tireNode
            if node == nil or node == 0 then node = vehicle.rootNode end
            tire.airSource = createAudioSource("rtwAirLeak", TireWear.AIR_SOUND, 30, 3, 0.65, 1)
            if tire.airSource ~= nil and tire.airSource ~= 0 then
                link(node, tire.airSource)
                setTranslation(tire.airSource, 0, 0, 0)
                setAudioSourceAutoPlay(tire.airSource, false)
                playSample(getAudioSourceSample(tire.airSource), 1, 0.65, 0, 0, 0)
            else
                tire.airSource = nil
            end
        end
    elseif not damaged then
        tire.punctureTimer = 0
        tire.airLoss = 0
        TireWear.stopAirSound(tire)
    end
    tire.damaged = damaged
end

function TireWear.applyAirVisual(tire)
    if not TireWear.isServiceableWheel(tire) then return  end

    local wheel = tire.wheel
    if wheel == nil or wheel.visualWheels == nil then return end
    local loss = tire.damaged and (tire.airLoss or 1) or 0
    local radius = TireWear.getOriginalPhysicsRadius(tire) or 0.5
    local extra = math.min(radius * TireWear.AIR_LOSS_RADIUS_RATIO, 0.14) * loss
    for _, visual in ipairs(wheel.visualWheels) do
        for _, part in ipairs(visual.visualParts or {}) do
            if part.isa ~= nil and WheelVisualPartTire ~= nil and part:isa(WheelVisualPartTire) then
                if part.rtwOriginalInitial == nil then
                    part.rtwOriginalInitial = part.initialDeformation or 0
                    part.rtwOriginalMax = part.maxDeformation or 0
                end
                part.initialDeformation = part.rtwOriginalInitial + extra
                part.maxDeformation = part.rtwOriginalMax + extra
            end
        end
    end
end

function TireWear.updateAirLoss(vehicle, dt)
    for index, tire in ipairs(vehicle.spec_tireWear.wheels or {}) do
        TireWear.tryPuncture(vehicle, tire, index, dt)
        if tire.damaged then
            tire.airLoss = math.min(1, (tire.airLoss or 1) + math.max(dt, 0) / TireWear.AIR_LOSS_MS)
            if tire.airLoss >= 1 then TireWear.stopAirSound(tire) end
        else
            tire.airLoss = 0
            TireWear.stopAirSound(tire)
        end
        TireWear.applyAirVisual(tire)
    end
end

function TireWear.getPunctureChancePercent(tire)
    local wear = TireWear.clamp(tonumber(tire.wear) or 0, 0, 1)
    local baseChance = TireWear.clamp(TireWear.PUNCTURE_CHANCE_PERCENT, 0, 100)
    return TireWear.clamp(baseChance * (1 + 7 * wear * wear), 0, 100)
end

function TireWear.tryPuncture(vehicle, tire, index, dt)
    if not TireWear.isServiceableWheel(tire) then return  end

    if not vehicle.isServer or tire.damaged or dt <= 0 then return end
    if vehicle.spec_tireWear == nil or vehicle.spec_tireWear.enabled ~= true then return end
    if tire.wheel == nil or TireReplaceEvent.isCrawlerWheel(tire) then return end
    if TireWear.getVehicleSpeedKmh(vehicle) < 1 or not TireWear.hasWheelGroundContact(tire) then return end
    tire.punctureTimer = (tire.punctureTimer or 0) + dt
    local interval = math.max(1000, TireWear.PUNCTURE_CHECK_MS)
    local chance = TireWear.getPunctureChancePercent(tire) / 100
    while tire.punctureTimer >= interval do
        tire.punctureTimer = tire.punctureTimer - interval
        if chance > 0 and math.random() < chance then
            TireWear.setAirDamage(vehicle, tire, true, false)
            TireWear.syncTireWearState(vehicle, index, true)
            break
        end
    end
end

function TireWear.getFlatTireCount(vehicle)
    local count, total = 0, 0
    for _, tire in ipairs((vehicle.spec_tireWear or {}).wheels or {}) do
        if TireWear.isServiceableWheel(tire) and not TireReplaceEvent.isCrawlerWheel(tire) then
            total = total + 1
            if tire.damaged then count = count + 1 end
        end
    end
    return count, total
end

function TireWear.hasFlatInCombination(vehicle, visited)
    visited = visited or {}
    if vehicle == nil or visited[vehicle] then return false end
    visited[vehicle] = true
    if TireWear.getFlatTireCount(vehicle) > 0 then return true end
    if vehicle.getAttachedImplements ~= nil then
        for _, implement in pairs(vehicle:getAttachedImplements() or {}) do
            if TireWear.hasFlatInCombination(implement.object, visited) then return true end
        end
    end
    return false
end

function TireWear:getSpeedLimit(superFunc, ...)
    local limit, doCheck = superFunc(self, ...)
    if TireWear.hasFlatInCombination(self) then
        return math.min(limit or math.huge, TireWear.FLAT_SPEED_LIMIT), true
    end
    return limit, doCheck
end

function TireWear:onDelete()
    for _, tire in ipairs((self.spec_tireWear or {}).wheels or {}) do
        TireWear.stopAirSound(tire)
    end
end


function TireWear.isExcludedVehicle(vehicle)
    if vehicle == nil then return false end
    local modName = "fs25_lsfmfarmequipmentpack"
    if type(vehicle.customEnvironment) == "string"
        and string.lower(vehicle.customEnvironment) == modName then
        return true
    end

    local function matchesPath(value)
        if type(value) ~= "string" then return false end
        local path = "/" .. string.lower(value):gsub("\\", "/") .. "/"
        return path:find("/" .. modName .. "/", 1, true) ~= nil
            or path:find("/" .. modName .. ".zip/", 1, true) ~= nil
    end

    return matchesPath(vehicle.configFileName) or matchesPath(vehicle.baseDirectory)
end


function TireWear:onLoad(
    savegame
)

    if TireWear.isExcludedVehicle(self) then
        self.spec_tireWear = {enabled = false, excluded = true, wheels = {}, totalDistance = 0}
        return
    end

    local vehicleName =
        "Unbekannt"

    if self.getName ~= nil then

        vehicleName =
            self:getName()
            or vehicleName

    end

    if self.spec_tireWear == nil then

        self.spec_tireWear =
            {}

    end

    local spec =
        self.spec_tireWear

    spec.enabled =
        self.xmlFile:getValue(
            "vehicle.tireWear#enabled",
            true
        )

    spec.lifetime =
        self.xmlFile:getValue(
            "vehicle.tireWear#lifetime",
            TireWear.DEFAULT_LIFETIME
        )

    if spec.lifetime == nil
        or spec.lifetime <= 0 then

        spec.lifetime =
            TireWear.DEFAULT_LIFETIME

    end

    spec.wheels =
        {}

    spec.totalDistance =
        0

    spec.lastX =
        nil

    spec.lastY =
        nil

    spec.lastZ =
        nil

    if self.spec_wheels ~= nil
        and self.spec_wheels.wheels ~= nil then

        for index, wheel in ipairs(
            self.spec_wheels.wheels
        ) do

            local originalPhysicsRadius =
                nil

            if wheel.physics ~= nil then

                originalPhysicsRadius =
                    tonumber(
                        wheel.physics.radiusOriginal
                    )
                    or tonumber(
                        wheel.physics.radius
                    )

            end

            spec.wheels[index] = {
                wear = 0,
                damaged = false,
                grip = TireWear.GRIP_NEW,

                owner = self,
                wheel = wheel,
                tireNode = nil,

                realTireWearNodes = {},
                dimensionLogged = false,

                originalPhysicsRadius = originalPhysicsRadius,
                currentPhysicsRadius = originalPhysicsRadius,
                visualMaxTreadDepth = 0,
                visualWearApplied = false,

                slip = 0,
                longitudinalSlip = 0,
                lateralSlip = 0,

                contactForce = 0,

                slipFactor = 1,
                loadFactor = 1,
                speedFactor = 1,

                groundFactor = 1,
                groundDepth = 0,
                groundType = "UNKNOWN",

                wearFactor = 1,

                failureRisk = 0,
                failureChance = 0,

                originalFrictionMultiplier = 0,
                finalFrictionMultiplier = 0,
                physicsGripApplied = 1,

                physicsValuesWarningShown = false,

                lastSentPackedWear = 0,
                lastSentDamaged = false,
                lastSyncDebugBucket = 0
            }

        end

    end

end

function TireWear:onPostLoad(
    savegame
)

    if self.spec_tireWear ~= nil and self.spec_tireWear.excluded then return end

    local spec =
        self.spec_tireWear

    if spec == nil
        or spec.wheels == nil then
        return
    end

    if savegame == nil
        or savegame.xmlFile == nil
        or savegame.key == nil then

        return

    end

    if savegame.resetVehicles == true then
        return
    end


    local saveKey =
        TireWear.getSavegameKey(
            savegame.key
        )

    if saveKey == nil then
        return
    end


    local loadedAnyValue =
        false


    for index, tire in ipairs(
        spec.wheels
    ) do

        local wheelKey =
            string.format(
                "%s.wheel(%d)",
                saveKey,
                index - 1
            )


        local wear =
            savegame.xmlFile:getValue(
                wheelKey .. "#wear",
                nil
            )



        if wear ~= nil then

            tire.wear =
                TireWear.clamp(
                    tonumber(
                        wear
                    )
                    or 0,
                    0,
                    1
                )

            loadedAnyValue =
                true

        end


        TireWear.setAirDamage(self, tire, savegame.xmlFile:getValue(wheelKey .. "#airLeak", false), true)
        tire.failureRisk = 0
        tire.failureChance = 0


        TireWear.updateGrip(
            tire
        )

    end


    TireWear.initializeNetworkSyncState(
        self
    )


    if loadedAnyValue then

        local vehicleName =
            "Fahrzeug"

        if self.getName ~= nil then

            vehicleName =
                self:getName()
                or vehicleName

        end

        TireWear.log(
            "Savegame-Reifendaten geladen: %s",
            vehicleName
        )

    end

end

function TireWear:saveToXMLFile(
    xmlFile,
    key,
    usedModNames
)

    if self.spec_tireWear ~= nil and self.spec_tireWear.excluded then return end

    local spec =
        self.spec_tireWear

    if spec == nil
        or spec.wheels == nil then
        return
    end


    local vehicleBaseKey =
        TireWear.getVehicleSavegameBaseKey(
            key
        )


    if vehicleBaseKey == nil then

        Logging.warning(
            "[RealTireWear] Savegame-Basiskey konnte nicht aus '%s' ermittelt werden",
            tostring(
                key
            )
        )

        return

    end


    local saveKey =
        TireWear.getSavegameKey(
            vehicleBaseKey
        )


    if saveKey == nil then
        return
    end


    for index, tire in ipairs(
        spec.wheels
    ) do

        local wheelKey =
            string.format(
                "%s.wheel(%d)",
                saveKey,
                index - 1
            )


        local wear =
            TireWear.clamp(
                tonumber(
                    tire.wear
                )
                or 0,
                0,
                1
            )


        xmlFile:setValue(
            wheelKey .. "#wear",
            wear
        )
        xmlFile:setValue(wheelKey .. "#airLeak", tire.damaged == true)


    end

end

function TireWear.packNetworkWear(
    wear
)

    wear =
        TireWear.clamp(
            tonumber(
                wear
            )
            or 0,
            0,
            1
        )


    return math.max(
        0,
        math.min(
            math.floor(
                wear
                *
                255
                +
                0.5
            ),
            255
        )
    )

end


function TireWear.getNetworkDebugBucket(
    wear
)

    wear =
        TireWear.clamp(
            tonumber(
                wear
            )
            or 0,
            0,
            1
        )


    return math.floor(
        wear
        *
        TireWear.NETWORK_SYNC_DEBUG_BUCKETS
        +
        0.000001
    )

end


function TireWear.initializeNetworkSyncState(
    self
)

    local spec =
        self.spec_tireWear


    if spec == nil
        or spec.wheels == nil then

        return

    end


    for _, tire in ipairs(
        spec.wheels
    ) do

        tire.lastSentPackedWear =
            TireWear.packNetworkWear(
                tire.wear
            )

        tire.lastSentDamaged =
            tire.damaged == true

        tire.lastSyncDebugBucket =
            TireWear.getNetworkDebugBucket(
                tire.wear
            )

    end

end


function TireWear.syncTireWearState(
    self,
    index,
    force
)

    if self == nil
        or self.isServer ~= true
        or g_server == nil then

        return false

    end


    if TireWearEvent == nil
        or TireWearEvent.sendEvent == nil then

        return false

    end


    local spec =
        self.spec_tireWear


    if spec == nil
        or spec.wheels == nil then

        return false

    end


    local tire =
        spec.wheels[index]


    if tire == nil then
        return false
    end


    local wear =
        TireWear.clamp(
            tonumber(
                tire.wear
            )
            or 0,
            0,
            1
        )


    local packedWear =
        TireWear.packNetworkWear(
            wear
        )


    local damaged =
        tire.damaged == true


    local packedChanged =
        tire.lastSentPackedWear == nil
        or tire.lastSentPackedWear ~= packedWear


    local damagedChanged =
        tire.lastSentDamaged == nil
        or tire.lastSentDamaged ~= damaged


    if force ~= true
        and not packedChanged
        and not damagedChanged then

        return false

    end


    TireWearEvent.sendEvent(
        self,
        index,
        wear,
        damaged
    )


    tire.lastSentPackedWear =
        packedWear

    tire.lastSentDamaged =
        damaged


    if TireWear.NETWORK_SYNC_DEBUG == true then

        local debugBucket =
            TireWear.getNetworkDebugBucket(
                wear
            )


        if force == true
            or damagedChanged
            or tire.lastSyncDebugBucket == nil
            or tire.lastSyncDebugBucket ~= debugBucket then

            local vehicleName =
                "Fahrzeug"


            if self.getName ~= nil then

                vehicleName =
                    self:getName()
                    or vehicleName

            end


        end


        tire.lastSyncDebugBucket =
            debugBucket

    end


    return true

end

function TireWear:onUpdateTick(
    dt
)

    if self.spec_tireWear ~= nil and self.spec_tireWear.excluded then return end

    local spec =
        self.spec_tireWear

    if spec == nil then
        return
    end

    TireWear.updateTireNodes(
        self
    )
    TireWear.updateAirLoss(self, dt)


    if spec.wheels ~= nil then

        for index, tire in ipairs(
            spec.wheels
        ) do

            TireWear.updateGrip(
                tire
            )

            TireWear.updateVisualWear(
                self,
                index
            )

            TireWear.updatePhysicalWear(
                self,
                index
            )

        end

    end

    if self.isClient == true then
        TireWear.updateCrawlerVisualWear(
            self,
            dt
        )
    end

    if not self.isServer then
        return
    end

    if spec.enabled ~= true then
        return
    end

    if self.rootNode == nil then
        return
    end

    if spec.wheels == nil
        or #spec.wheels == 0 then
        return
    end

    local x,
          y,
          z =
        getWorldTranslation(
            self.rootNode
        )

    if spec.lastX ~= nil then

        local dx =
            x - spec.lastX

        local dy =
            y - spec.lastY

        local dz =
            z - spec.lastZ

        local distance =
            math.sqrt(
                dx * dx
                +
                dy * dy
                +
                dz * dz
            )

        if distance > 0.001
            and distance < 20 then

            spec.totalDistance =
                (spec.totalDistance or 0)
                +
                distance

            TireWear.addWear(
                self,
                distance
            )

        end

    end

    spec.lastX =
        x

    spec.lastY =
        y

    spec.lastZ =
        z

end

function TireWear.addWear(
    self,
    distance
)

    local spec =
        self.spec_tireWear

    if spec == nil
        or spec.wheels == nil then
        return
    end

    local lifetime =
        tonumber(
            spec.lifetime
        )
        or TireWear.DEFAULT_LIFETIME

    if lifetime <= 0 then

        lifetime =
            TireWear.DEFAULT_LIFETIME

    end

    distance =
        math.max(
            tonumber(
                distance
            )
            or 0,
            0
        )

    if distance <= 0 then
        return
    end


    local speedKmh =
        TireWear.getVehicleSpeedKmh(
            self
        )

    local speedFactor =
        TireWear.getSpeedFactor(
            speedKmh
        )


    local averageContactForce =
        TireWear.getAverageContactForce(
            spec
        )


    for index, tire in ipairs(
        spec.wheels
    ) do

        tire.wear =
            TireWear.clamp(
                tonumber(
                    tire.wear
                )
                or 0,
                0,
                1
            )

        tire.failureRisk = 0
        tire.failureChance = 0


        local wearFactor =
            TireWear.calculateWheelWearFactor(
                tire,
                averageContactForce,
                speedFactor
            )


        if tire.wear < 1
            and wearFactor > 0 then

            local effectiveDistance =
                distance
                *
                wearFactor

            local wearIncrease =
                effectiveDistance
                /
                lifetime

            tire.wear =
                math.min(
                    1,
                    tire.wear
                    +
                    wearIncrease
                )

        end


        TireWear.updateGrip(
            tire
        )


        TireWear.updateVisualWear(
            self,
            index
        )


        TireWear.updatePhysicalWear(
            self,
            index
        )



        TireWear.syncTireWearState(
            self,
            index,
            false
        )

    end

end

function TireWear:repairTires()

    local spec =
        self.spec_tireWear

    if spec == nil
        or spec.wheels == nil then
        return
    end

    for index, tire in ipairs(
        spec.wheels
    ) do

        tire.wear =
            0

        TireWear.setAirDamage(self, tire, false, true)
        TireWear.applyAirVisual(tire)

        tire.grip =
            TireWear.GRIP_NEW

        tire.slip =
            0

        tire.longitudinalSlip =
            0

        tire.lateralSlip =
            0

        tire.contactForce =
            0

        tire.slipFactor =
            1

        tire.loadFactor =
            1

        tire.speedFactor =
            1

        tire.groundFactor =
            1

        tire.groundDepth =
            0

        tire.groundType =
            "UNKNOWN"

        tire.wearFactor =
            1

        tire.failureRisk =
            0

        tire.failureChance =
            0

        tire.physicsGripApplied =
            1

        tire.lastSentPackedWear =
            0

        tire.lastSentDamaged =
            tire.damaged == true

        tire.lastSyncDebugBucket =
            0

        TireWear.syncTireWearState(self, index, true)

        TireWear.restorePhysicalRadius(
            self,
            tire
        )


        TireWear.updateVisualWear(
            self,
            index
        )


        TireWear.updatePhysicalWear(
            self,
            index
        )

    end

    if self.isClient == true
        and self.spec_crawlers ~= nil
        and TireWear.updateCrawlerVisualWear ~= nil then

        spec.trackVisualUpdateTimer = TireWear.TRACK_VISUAL_UPDATE_MS
        TireWear.updateCrawlerVisualWear(self, 0)
    end

end

function TireWear:getTireWear(
    index
)

    local spec =
        self.spec_tireWear

    if spec == nil
        or spec.wheels == nil then
        return 0
    end

    local tire =
        spec.wheels[index]

    if tire == nil then
        return 0
    end

    return tonumber(
        tire.wear
    )
    or 0

end

function TireWear:onWriteStream(
    streamId,
    connection
)

    local spec =
        self.spec_tireWear

    if spec == nil
        or spec.wheels == nil then

        streamWriteUInt8(
            streamId,
            0
        )

        return

    end

    local count =
        math.min(
            #spec.wheels,
            255
        )

    streamWriteUInt8(
        streamId,
        count
    )

    for index = 1, count do

        local tire =
            spec.wheels[index]

        local wear =
            TireWear.clamp(
                tonumber(
                    tire.wear
                )
                or 0,
                0,
                1
            )

        streamWriteUInt8(
            streamId,
            math.floor(
                wear
                *
                255
                +
                0.5
            )
        )

        streamWriteBool(
            streamId,
            tire.damaged == true
        )

    end

end

function TireWear:onReadStream(
    streamId,
    connection
)

    if self.spec_tireWear ~= nil and self.spec_tireWear.excluded then
        local count = streamReadUInt8(streamId)
        for index = 1, count do
            streamReadUInt8(streamId)
            streamReadBool(streamId)
        end
        return
    end

    if self.spec_tireWear == nil then

        self.spec_tireWear =
            {}

    end

    local spec =
        self.spec_tireWear

    if spec.wheels == nil then

        spec.wheels =
            {}

    end

    local count =
        streamReadUInt8(
            streamId
        )

    for index = 1, count do

        local wear =
            streamReadUInt8(
                streamId
            )
            /
            255

        local damaged = streamReadBool(
            streamId
        )

        if spec.wheels[index] == nil then

            spec.wheels[index] = {
                wear = 0,
                damaged = false,
                grip = TireWear.GRIP_NEW,

                owner = self,
                wheel = nil,
                tireNode = nil,

                realTireWearNodes = {},
                dimensionLogged = false,

                originalPhysicsRadius = nil,
                currentPhysicsRadius = nil,
                visualMaxTreadDepth = 0,
                visualWearApplied = false,

                slip = 0,
                longitudinalSlip = 0,
                lateralSlip = 0,

                contactForce = 0,

                slipFactor = 1,
                loadFactor = 1,
                speedFactor = 1,

                groundFactor = 1,
                groundDepth = 0,
                groundType = "UNKNOWN",

                wearFactor = 1,

                failureRisk = 0,
                failureChance = 0,

                originalFrictionMultiplier = 0,
                finalFrictionMultiplier = 0,
                physicsGripApplied = 1,

                physicsValuesWarningShown = false,

                lastSentPackedWear = 0,
                lastSentDamaged = false,
                lastSyncDebugBucket = 0
            }

        end

        spec.wheels[index].wear =
            wear

        TireWear.setAirDamage(self, spec.wheels[index], damaged, true)

        TireWear.updateGrip(
            spec.wheels[index]
        )

    end

end


TireWearEvent = {}
local TireWearEvent_mt = Class(TireWearEvent, Event)
InitEventClass(TireWearEvent, "TireWearEvent")

function TireWearEvent.emptyNew()
    return Event.new(TireWearEvent_mt)
end

function TireWearEvent.new(vehicle, wheelIndex, wear, damaged)
    local self = TireWearEvent.emptyNew()
    self.vehicle = vehicle
    self.wheelIndex = wheelIndex or 1
    self.wear = math.max(0, math.min(tonumber(wear) or 0, 1))
    self.damaged = damaged == true
    return self
end

function TireWearEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.wheelIndex = streamReadUInt8(streamId)
    self.wear = streamReadUInt8(streamId) / 255
    self.damaged = streamReadBool(streamId)
    self:run(connection)
end

function TireWearEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUInt8(streamId, math.max(0, math.min(self.wheelIndex, 255)))
    local packedWear = math.floor(self.wear * 255 + 0.5)
    streamWriteUInt8(streamId, math.max(0, math.min(packedWear, 255)))
    streamWriteBool(streamId, self.damaged == true)
end

function TireWearEvent:run(connection)
    if connection ~= nil and not connection:getIsServer() then return end
    local vehicle = self.vehicle
    if vehicle == nil then return end

    if vehicle.getIsSynchronized ~= nil and not vehicle:getIsSynchronized() then
        return
    end

    local spec = vehicle.spec_tireWear
    if spec == nil or spec.wheels == nil then return end

    local tire = spec.wheels[self.wheelIndex]
    if tire == nil then return end

    tire.wear = math.max(0, math.min(tonumber(self.wear) or 0, 1))
    TireWear.setAirDamage(vehicle, tire, self.damaged, false)
    TireWear.applyAirVisual(tire)

    if TireWear ~= nil and TireWear.updateGrip ~= nil then
        TireWear.updateGrip(tire)
    end

    if TireWear ~= nil and TireWear.updateVisualWear ~= nil then
        TireWear.updateVisualWear(vehicle, self.wheelIndex)
    end

    if TireWear ~= nil and TireWear.updatePhysicalWear ~= nil then
        TireWear.updatePhysicalWear(vehicle, self.wheelIndex)
    end

    if vehicle.isClient == true
        and TireWear ~= nil
        and TireWear.updateCrawlerVisualWear ~= nil
        and vehicle.spec_crawlers ~= nil then

        spec.trackVisualUpdateTimer = TireWear.TRACK_VISUAL_UPDATE_MS
        TireWear.updateCrawlerVisualWear(vehicle, 0)
    end

    if connection ~= nil and not connection:getIsServer() and g_server ~= nil then
        g_server:broadcastEvent(
            TireWearEvent.new(vehicle, self.wheelIndex, tire.wear, tire.damaged),
            false,
            connection,
            vehicle
        )
    end
end

function TireWearEvent.sendEvent(vehicle, wheelIndex, wear, damaged)
    if vehicle == nil then return end

    if g_server ~= nil then
        g_server:broadcastEvent(
            TireWearEvent.new(vehicle, wheelIndex, wear, damaged),
            false,
            nil,
            vehicle
        )
        return
    end

    if g_client ~= nil and g_client:getServerConnection() ~= nil then
        g_client:getServerConnection():sendEvent(
            TireWearEvent.new(vehicle, wheelIndex, wear, damaged)
        )
    end
end

TireReplaceEvent = {}
local TireReplaceEvent_mt = Class(TireReplaceEvent, Event)
InitEventClass(TireReplaceEvent, "TireReplaceEvent")

TireReplaceEvent.MODE_ALL = 0
TireReplaceEvent.MODE_FRONT = 1
TireReplaceEvent.MODE_REAR = 2

TireReplaceEvent.SET_PRICE_FACTOR = 0.025
TireReplaceEvent.DAMAGED_EXTRA_FACTOR = 0.0

function TireReplaceEvent.clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

function TireReplaceEvent.emptyNew()
    return Event.new(TireReplaceEvent_mt)
end

function TireReplaceEvent.new(vehicle, mode)
    local self = TireReplaceEvent.emptyNew()
    self.vehicle = vehicle
    self.mode = mode or TireReplaceEvent.MODE_ALL
    return self
end

function TireReplaceEvent.getWheelLocalZ(vehicle, tire)
    if vehicle == nil or tire == nil or tire.wheel == nil then return nil end

    local wheel = tire.wheel
    local node = wheel.repr
    if node == nil or node == 0 then node = wheel.driveNode end

    if node == nil or node == 0 or vehicle.rootNode == nil
        or getWorldTranslation == nil or worldToLocal == nil then
        return nil
    end

    local wx, wy, wz = getWorldTranslation(node)
    local lx, ly, lz = worldToLocal(vehicle.rootNode, wx, wy, wz)
    return lz
end

function TireReplaceEvent.isCrawlerWheel(tire)
    if tire == nil or tire.wheel == nil then
        return false
    end

    local wheel = tire.wheel

    if WheelsUtil ~= nil
        and WheelsUtil.getTireType ~= nil then

        local crawlerType =
            WheelsUtil.getTireType(
                "crawler"
            )

        local runtimeTireType =
            wheel.tireType

        if runtimeTireType == nil
            and wheel.physics ~= nil then

            runtimeTireType =
                wheel.physics.tireType

        end

        if crawlerType ~= nil
            and runtimeTireType == crawlerType then

            return true

        end

    end

    local tireType =
        wheel.tireType

    if tireType == nil
        and wheel.physics ~= nil then

        tireType =
            wheel.physics.tireType

    end

    if type(tireType) == "string" then

        local value =
            string.lower(
                tireType
            )

        if string.find(
            value,
            "crawler",
            1,
            true
        ) ~= nil then

            return true

        end

    end

    local node =
        wheel.repr

    if (node == nil or node == 0)
        and wheel.driveNode ~= nil then

        node =
            wheel.driveNode

    end

    if node ~= nil
        and node ~= 0
        and getName ~= nil then

        local nodeName =
            getName(
                node
            )

        if nodeName ~= nil then

            local value =
                string.lower(
                    tostring(
                        nodeName
                    )
                )

            if string.find(
                value,
                "crawler",
                1,
                true
            ) ~= nil then

                return true

            end

        end

    end

    return false
end

function TireReplaceEvent.isCrawlerServiceVehicle(vehicle)
    if vehicle == nil
        or vehicle.spec_tireWear == nil
        or vehicle.spec_tireWear.wheels == nil then

        return false
    end

    local wheels = vehicle.spec_tireWear.wheels
    local count = #wheels

    if count < 8 or count % 2 ~= 0 then
        return false
    end

    for _, tire in ipairs(wheels) do
        if not TireReplaceEvent.isCrawlerWheel(tire) then
            return false
        end
    end

    return true
end

TireReplaceEvent.MODE_AXLE_BASE = 10

function TireReplaceEvent.buildAxleGroups(vehicle)
    local wheels = vehicle.spec_tireWear and vehicle.spec_tireWear.wheels or {}
    local entries = {}
    for index, tire in ipairs(wheels) do
        if TireWear.isServiceableWheel(tire) then
            local z = TireReplaceEvent.getWheelLocalZ(vehicle, tire)
            entries[#entries + 1] = {index = index, z = z}
        end
    end
    local spec = vehicle.spec_tireWear
    local membership = {}
    for _, entry in ipairs(entries) do membership[#membership + 1] = entry.index end
    local signature = table.concat(membership, ",")
    local cache = spec and spec.serviceAxleGroups
    if cache ~= nil and cache.wheels == wheels and cache.count == #wheels and cache.signature == signature then
        return cache.groups
    end
    local known = true
    for _, entry in ipairs(entries) do
        if entry.z == nil then known = false end
    end
    local groups = {}
    if known then
        table.sort(entries, function(a, b)
            if a.z == b.z then return a.index < b.index end
            return a.z > b.z
        end)
        for _, entry in ipairs(entries) do
            local group = groups[#groups]
            if group == nil or math.abs(entry.z - group.z) > 0.10 then
                group = {z = entry.z, indices = {}}
                groups[#groups + 1] = group
            end
            group.indices[#group.indices + 1] = entry.index
        end
    else
        for ordinal, entry in ipairs(entries) do
            local index = entry.index
            local axle = math.ceil(ordinal / 2)
            groups[axle] = groups[axle] or {indices = {}}
            table.insert(groups[axle].indices, index)
        end
    end
    for _, group in ipairs(groups) do table.sort(group.indices) end
    if known and spec ~= nil then
        spec.serviceAxleGroups = {wheels = wheels, count = #wheels, signature = signature, groups = groups}
    end
    return groups
end

function TireReplaceEvent.getServiceAxles(vehicle)
    local function text(key)
        return g_i18n:getText(key, TireWear.MOD_NAME)
    end
    if TireReplaceEvent.isCrawlerServiceVehicle(vehicle) then
        return {{mode = TireReplaceEvent.MODE_FRONT, title = text("rtw_axle_front")},
                {mode = TireReplaceEvent.MODE_REAR, title = text("rtw_axle_rear")}}
    end
    local groups = TireReplaceEvent.buildAxleGroups(vehicle)
    local count = #groups
    local split = math.ceil(count / 2)
    local largestGap = -1
    for index = 1, count - 1 do
        local frontZ, rearZ = groups[index].z, groups[index + 1].z
        if frontZ ~= nil and rearZ ~= nil then
            local gap = math.abs(frontZ - rearZ)
            if gap > largestGap + 0.01
                or (math.abs(gap - largestGap) <= 0.01
                    and math.abs(index - count / 2) < math.abs(split - count / 2)) then
                largestGap, split = gap, index
            end
        end
    end
    local result = {}
    for index = 1, count do
        local title = text("rtw_axle_single")
        if count > 1 then
            local isFront = index <= split
            local sideCount = isFront and split or count - split
            local sideIndex = isFront and index or index - split
            local key = isFront and "rtw_axle_front" or "rtw_axle_rear"
            title = text(key)
            if sideCount > 1 then title = string.format(text(key .. "_numbered"), sideIndex) end
        end
        result[#result + 1] = {mode = TireReplaceEvent.MODE_AXLE_BASE + index, title = title}
    end
    return result
end

function TireReplaceEvent.buildAxleMap(vehicle)
    local result = {}
    if vehicle == nil or vehicle.spec_tireWear == nil
        or vehicle.spec_tireWear.wheels == nil then
        return result
    end

    local wheels = vehicle.spec_tireWear.wheels
    local positions = {}
    local minZ = nil
    local maxZ = nil

    for index, tire in ipairs(wheels) do
        local z = TireReplaceEvent.getWheelLocalZ(vehicle, tire)
        positions[index] = z

        if z ~= nil then
            minZ = minZ == nil and z or math.min(minZ, z)
            maxZ = maxZ == nil and z or math.max(maxZ, z)
        end
    end

    if minZ ~= nil and maxZ ~= nil and math.abs(maxZ - minZ) > 0.10 then
        local splitZ = (minZ + maxZ) * 0.5
        for index = 1, #wheels do
            local z = positions[index]
            if z ~= nil and z >= splitZ then
                result[index] = TireReplaceEvent.MODE_FRONT
            else
                result[index] = TireReplaceEvent.MODE_REAR
            end
        end
        return result
    end

    local splitIndex = math.ceil(#wheels / 2)
    for index = 1, #wheels do
        result[index] = index <= splitIndex
            and TireReplaceEvent.MODE_FRONT
            or TireReplaceEvent.MODE_REAR
    end

    return result
end

function TireReplaceEvent.buildServiceUnits(vehicle)
    local result = {}

    if vehicle == nil
        or vehicle.spec_tireWear == nil
        or vehicle.spec_tireWear.wheels == nil then

        return result
    end

    local wheels = vehicle.spec_tireWear.wheels

    if TireReplaceEvent.isCrawlerServiceVehicle(vehicle) then
        local unitCount = math.floor(#wheels / 2)
        local frontUnitCount = math.floor(unitCount / 2)

        for unitIndex = 1, unitCount do
            local firstIndex = (unitIndex - 1) * 2 + 1
            local secondIndex = firstIndex + 1

            result[#result + 1] = {
                indices = {firstIndex, secondIndex},
                representativeIndex = firstIndex,
                isCrawler = true,
                isLeft = unitIndex % 2 == 1,
                hasSide = true,
                mode = unitIndex <= frontUnitCount
                    and TireReplaceEvent.MODE_FRONT
                    or TireReplaceEvent.MODE_REAR
            }
        end

        return result
    end

    local axleMap = TireReplaceEvent.buildAxleMap(vehicle)

    for index, tire in ipairs(wheels) do
        if TireWear.isServiceableWheel(tire) then
        result[#result + 1] = {
            indices = {index},
            representativeIndex = index,
            isCrawler = false,
            isLeft = tire ~= nil
                and tire.wheel ~= nil
                and tire.wheel.isLeft == true,
            hasSide = tire ~= nil
                and tire.wheel ~= nil
                and tire.wheel.isLeft ~= nil,
            mode = axleMap[index]
        }
        end
    end

    return result
end

function TireReplaceEvent.getServiceUnits(vehicle, mode)
    local result = {}
    local axleIndices
    if type(mode) == "number" and mode > TireReplaceEvent.MODE_AXLE_BASE then
        local group = TireReplaceEvent.buildAxleGroups(vehicle)[mode - TireReplaceEvent.MODE_AXLE_BASE]
        if group == nil then return result end
        axleIndices = {}
        for _, index in ipairs(group.indices) do axleIndices[index] = true end
    end

    for _, unit in ipairs(TireReplaceEvent.buildServiceUnits(vehicle)) do
        if mode == nil
            or mode == TireReplaceEvent.MODE_ALL
            or unit.mode == mode
            or (axleIndices ~= nil and axleIndices[unit.representativeIndex]) then

            result[#result + 1] = unit
        end
    end

    return result
end

function TireReplaceEvent.getServiceUnitState(vehicle, unit)
    if vehicle == nil
        or unit == nil
        or vehicle.spec_tireWear == nil
        or vehicle.spec_tireWear.wheels == nil then

        return 0, false
    end

    local wearSum = 0
    local count = 0
    local damaged = false

    for _, index in ipairs(unit.indices or {}) do
        local tire = vehicle.spec_tireWear.wheels[index]

        if tire ~= nil then
            wearSum = wearSum
                + TireReplaceEvent.clamp(tonumber(tire.wear) or 0, 0, 1)
            count = count + 1
            damaged = damaged or tire.damaged == true

        end
    end

    if count == 0 then
        return 0, damaged
    end

    return wearSum / count, damaged
end

function TireReplaceEvent.getWheelMode(vehicle, wheelIndex)
    for _, unit in ipairs(TireReplaceEvent.buildServiceUnits(vehicle)) do
        for _, index in ipairs(unit.indices or {}) do
            if index == wheelIndex then
                return unit.mode
            end
        end
    end

    return nil
end

function TireReplaceEvent.getWheelIndices(vehicle, mode)
    local result = {}
    local seen = {}

    for _, unit in ipairs(TireReplaceEvent.getServiceUnits(vehicle, mode)) do
        for _, index in ipairs(unit.indices or {}) do
            if not seen[index] then
                seen[index] = true
                result[#result + 1] = index
            end
        end
    end

    table.sort(result)

    return result
end

function TireReplaceEvent.getTireData(vehicle, mode)
    if vehicle == nil or vehicle.spec_tireWear == nil
        or vehicle.spec_tireWear.wheels == nil then
        return 0, 0, 0
    end

    local units = TireReplaceEvent.getServiceUnits(vehicle, mode)
    local wearSum = 0
    local count = 0
    local damagedCount = 0

    for _, unit in ipairs(units) do
        local wear, damaged =
            TireReplaceEvent.getServiceUnitState(vehicle, unit)

        wearSum = wearSum + wear
        count = count + 1

        if damaged then
            damagedCount = damagedCount + 1
        end
    end

    if count == 0 then return 0, 0, 0 end
    return wearSum / count, damagedCount, count
end

function TireReplaceEvent.getVehiclePrice(vehicle)
    if vehicle == nil then return 0 end

    if vehicle.getPrice ~= nil then
        local price = tonumber(vehicle:getPrice())
        if price ~= nil and price > 0 then return price end
    end

    if vehicle.configFileName ~= nil and g_storeManager ~= nil then
        local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
        if storeItem ~= nil then
            local price = tonumber(storeItem.price)
            if price ~= nil and price > 0 then return price end
        end
    end

    return 0
end

function TireReplaceEvent.getPrice(vehicle, mode)
    if vehicle == nil or vehicle.spec_tireWear == nil
        or vehicle.spec_tireWear.wheels == nil then
        return 0
    end

    local vehiclePrice = TireReplaceEvent.getVehiclePrice(vehicle)
    if vehiclePrice <= 0 then return 0 end

    local averageWear, damagedCount, selectedCount =
        TireReplaceEvent.getTireData(vehicle, mode)

    if selectedCount <= 0 then return 0 end

    local _, _, totalCount =
        TireReplaceEvent.getTireData(
            vehicle,
            TireReplaceEvent.MODE_ALL
        )

    if totalCount <= 0 then return 0 end

    local fullSetPrice = vehiclePrice * TireReplaceEvent.SET_PRICE_FACTOR
    local selectedSetPrice = fullSetPrice * (selectedCount / totalCount)
    local wearPrice = selectedSetPrice * math.max(averageWear, 0.25 * damagedCount / selectedCount)

    return math.floor(math.max(0, wearPrice) + 0.5)
end

function TireReplaceEvent.needsReplacement(vehicle, mode)
    if vehicle == nil or vehicle.spec_tireWear == nil
        or vehicle.spec_tireWear.wheels == nil then
        return false
    end

    local indices = TireReplaceEvent.getWheelIndices(vehicle, mode)
    for _, index in ipairs(indices) do
        local tire = vehicle.spec_tireWear.wheels[index]
        if tire ~= nil then
            local wear = tonumber(tire.wear) or 0
            if wear > 0.001 or tire.damaged then
                return true
            end
        end
    end

    return false
end

function TireReplaceEvent.getFarmMoney(farmId)
    if farmId == nil or g_farmManager == nil then return nil end
    local farm = g_farmManager:getFarmById(farmId)
    if farm == nil then return nil end
    return tonumber(farm.money)
end

function TireReplaceEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.mode = streamReadUInt8(streamId)
    self:run(connection)
end

function TireReplaceEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUInt8(
        streamId,
        math.max(0, math.min(self.mode or TireReplaceEvent.MODE_ALL, 255))
    )
end

function TireReplaceEvent.resetWheel(vehicle, index)
    if vehicle == nil or vehicle.spec_tireWear == nil
        or vehicle.spec_tireWear.wheels == nil then
        return
    end

    local tire = vehicle.spec_tireWear.wheels[index]
    if tire == nil then return end

    tire.wear = 0
    TireWear.setAirDamage(vehicle, tire, false, true)
    TireWear.applyAirVisual(tire)
    tire.grip = 1

    if TireWear ~= nil and TireWear.updateGrip ~= nil then
        TireWear.updateGrip(tire)
    end

    if TireWear ~= nil and TireWear.updateVisualWear ~= nil then
        TireWear.updateVisualWear(vehicle, index)
    end

    if TireWear ~= nil and TireWear.updatePhysicalWear ~= nil then
        TireWear.updatePhysicalWear(vehicle, index)
    end
end

function TireReplaceEvent:run(connection)
    if g_server == nil then return end

    local vehicle = self.vehicle
    local mode = self.mode or TireReplaceEvent.MODE_ALL

    if vehicle == nil then
        Logging.warning("[RealTireWear] Reifenwechsel: Fahrzeug fehlt")
        return
    end

    if vehicle.spec_tireWear == nil or vehicle.spec_tireWear.wheels == nil then
        Logging.warning("[RealTireWear] Reifenwechsel: TireWear-Daten fehlen")
        return
    end

    if not TireReplaceEvent.needsReplacement(vehicle, mode) then return end

    local price = TireReplaceEvent.getPrice(vehicle, mode)
    if price <= 0 then
        Logging.warning("[RealTireWear] Reifenwechsel: Ungueltiger Preis")
        return
    end

    local farmId = nil
    if vehicle.getOwnerFarmId ~= nil then farmId = vehicle:getOwnerFarmId() end

    if farmId == nil then
        Logging.warning("[RealTireWear] Reifenwechsel: FarmId fehlt")
        return
    end

    local farmMoney = TireReplaceEvent.getFarmMoney(farmId)
    if farmMoney ~= nil and farmMoney < price then
        return
    end

    if g_currentMission ~= nil then
        g_currentMission:addMoney(
            -price,
            farmId,
            MoneyType.VEHICLE_REPAIR,
            true,
            true
        )
    end

    local indices = TireReplaceEvent.getWheelIndices(vehicle, mode)
    for _, index in ipairs(indices) do
        TireReplaceEvent.resetWheel(vehicle, index)
    end

    if vehicle.isClient == true
        and TireWear ~= nil
        and TireWear.updateCrawlerVisualWear ~= nil
        and vehicle.spec_crawlers ~= nil then

        vehicle.spec_tireWear.trackVisualUpdateTimer =
            TireWear.TRACK_VISUAL_UPDATE_MS
        TireWear.updateCrawlerVisualWear(vehicle, 0)
    end

    local vehicleName = "Fahrzeug"
    if vehicle.getName ~= nil then vehicleName = vehicle:getName() or vehicleName end

    local modeText = "alle Reifen"
    if mode == TireReplaceEvent.MODE_FRONT then
        modeText = "Vorderachse"
    elseif mode == TireReplaceEvent.MODE_REAR then
        modeText = "Hinterachse"
    end

    for _, index in ipairs(indices) do
        local tire = vehicle.spec_tireWear.wheels[index]
        if tire ~= nil then
            TireWearEvent.sendEvent(
                vehicle,
                index,
                tire.wear or 0,
                false
            )
        end
    end
end

function TireReplaceEvent.sendEvent(vehicle, mode)
    if vehicle == nil then return end
    mode = mode or TireReplaceEvent.MODE_ALL

    if g_server ~= nil then
        local event = TireReplaceEvent.new(vehicle, mode)
        event:run(nil)
        return
    end

    if g_client ~= nil and g_client:getServerConnection() ~= nil then
        g_client:getServerConnection():sendEvent(
            TireReplaceEvent.new(vehicle, mode)
        )
    end
end

TireWearWarningIcon = {}

TireWearWarningIcon.WARNING_WEAR =
    0.95

TireWearWarningIcon.BLINK_PERIOD_MS =
    900

TireWearWarningIcon.BLINK_VISIBLE_MS =
    600

local MOD_DIRECTORY =
    g_currentModDirectory or ""

TireWearWarningIcon.ICON_FILENAME =
    MOD_DIRECTORY .. "icons/tireWarning.dds"

TireWearWarningIcon.iconOverlay =
    nil

TireWearWarningIcon.OFFSET_X_PX =
    137

TireWearWarningIcon.OFFSET_Y_PX =
    219

TireWearWarningIcon.SIZE_PX =
    17

TireWearWarningIcon.TEXT_SIZE_PX =
    12

TireWearWarningIcon.BORDER_PX =
    1.25

TireWearWarningIcon.COLOR_WARNING = {
    1.00,
    0.84,
    0.00,
    1.00
}


TireWearWarningIcon.COLOR_CRITICAL = {
    1.00,
    0.08,
    0.05,
    1.00
}


TireWearWarningIcon.COLOR_BACKGROUND = {
    0.035,
    0.035,
    0.035,
    0.88
}

function TireWearWarningIcon.getIconOverlay()

    if TireWearWarningIcon.iconOverlay ~= nil then
        return TireWearWarningIcon.iconOverlay
    end


    if Overlay == nil then
        return nil
    end


    TireWearWarningIcon.iconOverlay =
        Overlay.new(
            TireWearWarningIcon.ICON_FILENAME,
            0,
            0,
            0.01,
            0.01
        )


    return TireWearWarningIcon.iconOverlay

end

function TireWearWarningIcon.getCurrentVehicle()

    if g_localPlayer == nil
        or g_localPlayer.getCurrentVehicle == nil then

        return nil

    end

    return g_localPlayer:getCurrentVehicle()

end

function TireWearWarningIcon.getWarningLevel(vehicle)

    if vehicle == nil
        or vehicle.spec_tireWear == nil
        or vehicle.spec_tireWear.wheels == nil then

        return 0

    end


    local warning =
        false


    for _, tire in ipairs(
        vehicle.spec_tireWear.wheels
    ) do

        local wear =
            tonumber(tire.wear)
            or 0


        if tire.damaged then return 2 end

        if wear >=
            TireWearWarningIcon.WARNING_WEAR then

            warning =
                true

        end

    end


    return warning
        and 1
        or 0

end

function TireWearWarningIcon.getSpeedMeter()

    if g_currentMission == nil
        or g_currentMission.hud == nil then

        return nil

    end


    local hud =
        g_currentMission.hud


    local candidates = {
        hud.speedMeter,
        hud.speedMeterDisplay,
        hud.speedMeterHud
    }


    for _, candidate in pairs(
        candidates
    ) do

        if type(candidate) == "table"
            and candidate.getPosition ~= nil then

            return candidate

        end

    end


    for _, candidate in pairs(hud) do

        if type(candidate) == "table"
            and candidate.speedBg ~= nil
            and candidate.getPosition ~= nil then

            return candidate

        end

    end


    return nil

end

function TireWearWarningIcon.getScaledVector(
    speedMeter,
    x,
    y
)

    if speedMeter ~= nil
        and speedMeter.scalePixelValuesToScreenVector ~= nil then

        return speedMeter:scalePixelValuesToScreenVector(
            x,
            y
        )

    end


    if getNormalizedScreenValues ~= nil then

        return getNormalizedScreenValues(
            x,
            y
        )

    end


    return x / 1920,
           y / 1080

end

function TireWearWarningIcon.getPosition()

    local speedMeter =
        TireWearWarningIcon.getSpeedMeter()


    local anchorX =
        g_hudAnchorRight
        or 0.985


    local anchorY =
        g_hudAnchorBottom
        or 0.025


    if speedMeter ~= nil
        and speedMeter.getPosition ~= nil then

        anchorX,
        anchorY =
            speedMeter:getPosition()

    end


    local offsetX,
          offsetY =
        TireWearWarningIcon.getScaledVector(
            speedMeter,
            TireWearWarningIcon.OFFSET_X_PX,
            TireWearWarningIcon.OFFSET_Y_PX
        )


    local sizeX,
          sizeY =
        TireWearWarningIcon.getScaledVector(
            speedMeter,
            TireWearWarningIcon.SIZE_PX,
            TireWearWarningIcon.SIZE_PX
        )


    return anchorX
        -
        offsetX
        -
        sizeX * 0.5,

        anchorY
        +
        offsetY
        -
        sizeY * 0.5,

        sizeX,
        sizeY,
        speedMeter

end

function TireWearWarningIcon.getBlinkVisible()

    local timeMs =
        g_time or 0


    return
        (
            timeMs
            %
            TireWearWarningIcon.BLINK_PERIOD_MS
        )
        <
        TireWearWarningIcon.BLINK_VISIBLE_MS

end

function TireWearWarningIcon.drawIcon(level)

    if level <= 0
        or not TireWearWarningIcon.getBlinkVisible() then

        return
    end


    local x,
          y,
          width,
          height =
        TireWearWarningIcon.getPosition()


    local color =
        level >= 2
        and TireWearWarningIcon.COLOR_CRITICAL
        or TireWearWarningIcon.COLOR_WARNING


    local overlay =
        TireWearWarningIcon.getIconOverlay()


    if overlay == nil then
        return
    end


    overlay:setPosition(
        x,
        y
    )


    overlay:setDimension(
        width,
        height
    )


    overlay:setColor(
        color[1],
        color[2],
        color[3],
        color[4]
    )


    overlay:render()

end

function TireWearWarningIcon:loadMap(mapName)
end

function TireWearWarningIcon:deleteMap()

    if TireWearWarningIcon.iconOverlay ~= nil then

        TireWearWarningIcon.iconOverlay:delete()
        TireWearWarningIcon.iconOverlay = nil

    end

end


function TireWearWarningIcon:update(dt)
end


function TireWearWarningIcon:draw()

    if TireWearWorkshop ~= nil
        and TireWearWorkshop.isWorkshopOpen == true then

        return

    end


    local vehicle =
        TireWearWarningIcon.getCurrentVehicle()


    local level =
        TireWearWarningIcon.getWarningLevel(
            vehicle
        )


    TireWearWarningIcon.drawIcon(
        level
    )

end


function TireWearWarningIcon:keyEvent(
    unicode,
    sym,
    modifier,
    isDown
)
end


function TireWearWarningIcon:mouseEvent(
    posX,
    posY,
    isDown,
    isUp,
    button
)
end


addModEventListener(
    TireWearWarningIcon
)

TireWearManager = {}

TireWearManager.LOCAL_SPEC_NAME =
    "tireWear"
	
TireWearManager.SPEC_NAME =
    g_currentModName .. ".tireWear"


TireWearManager.CLASS_NAME =
    "TireWear"


TireWearManager.SCRIPT_FILE =
    Utils.getFilename(
        "scripts/RealTireWear.lua",
        g_currentModDirectory
    )

function TireWearManager.log(
    text,
    ...
)
end

function TireWearManager.getSpecializationObject()

    if g_specializationManager == nil then
        return nil
    end


    return g_specializationManager:getSpecializationObjectByName(
        TireWearManager.SPEC_NAME
    )

end

function TireWearManager.registerSpecialization()

    if g_specializationManager == nil then

        Logging.error(
            "[RealTireWear] g_specializationManager fehlt"
        )

        return false

    end


    local specObject =
        TireWearManager.getSpecializationObject()


    if specObject ~= nil then

        TireWearManager.log(
            "Specialization bereits vorhanden: %s",
            TireWearManager.SPEC_NAME
        )

        return true

    end


    TireWearManager.log(
        "Registriere Specialization: %s",
        TireWearManager.SPEC_NAME
    )

    g_specializationManager:addSpecialization(
        TireWearManager.LOCAL_SPEC_NAME,
        TireWearManager.CLASS_NAME,
        TireWearManager.SCRIPT_FILE,
        g_currentModName
    )

    specObject =
        TireWearManager.getSpecializationObject()


    if specObject == nil then

        Logging.error(
            "[RealTireWear] Specialization ist nach Registrierung nicht vorhanden"
        )

        return false

    end


    TireWearManager.log(
        "Specialization erfolgreich registriert: %s",
        TireWearManager.SPEC_NAME
    )


    return true

end

function TireWearManager.hasWheels(
    vehicleType
)

    if vehicleType == nil then
        return false
    end


    if vehicleType.specializations == nil then
        return false
    end


    return SpecializationUtil.hasSpecialization(
        Wheels,
        vehicleType.specializations
    )

end

function TireWearManager.hasTireWear(
    vehicleType
)

    if vehicleType == nil then
        return false
    end

    if vehicleType.specializationsByName ~= nil then

        if vehicleType.specializationsByName[
            TireWearManager.SPEC_NAME
        ] ~= nil then

            return true

        end

    end

    if vehicleType.specializationNames ~= nil then

        for _, specName in pairs(
            vehicleType.specializationNames
        ) do

            if specName ==
                TireWearManager.SPEC_NAME then

                return true

            end

        end

    end

    local tireWearObject =
        TireWearManager.getSpecializationObject()


    if tireWearObject ~= nil
        and vehicleType.specializations ~= nil then

        for _, spec in pairs(
            vehicleType.specializations
        ) do

            if spec == tireWearObject then

                return true

            end

        end

    end


    return false

end

function TireWearManager.addToVehicleType(
    typeName,
    vehicleType
)

    if TireWearManager.hasTireWear(
        vehicleType
    ) then

        return true,
               false

    end


    g_vehicleTypeManager:addSpecialization(
        typeName,
        TireWearManager.SPEC_NAME
    )

    if TireWearManager.hasTireWear(
        vehicleType
    ) then

        return true,
               true

    end


    return false,
           false

end

function TireWearManager.registerVehicleTypes()

    if g_vehicleTypeManager == nil then

        Logging.error(
            "[RealTireWear] g_vehicleTypeManager fehlt"
        )

        return false

    end


    if g_vehicleTypeManager.types == nil then

        Logging.error(
            "[RealTireWear] g_vehicleTypeManager.types fehlt"
        )

        return false

    end


    local added =
        0

    local existing =
        0

    local failed =
        0

    local wheelTypes =
        0


    for typeName, vehicleType in pairs(
        g_vehicleTypeManager.types
    ) do

        if TireWearManager.hasWheels(
            vehicleType
        ) then

            wheelTypes =
                wheelTypes
                +
                1


            local success,
                  wasAdded =
                TireWearManager.addToVehicleType(
                    typeName,
                    vehicleType
                )


            if success then

                if wasAdded then

                    added =
                        added
                        +
                        1

                else

                    existing =
                        existing
                        +
                        1

                end

            else

                failed =
                    failed
                    +
                    1


                Logging.warning(
                    "[RealTireWear] TireWear Registrierung fehlgeschlagen: %s",
                    tostring(
                        typeName
                    )
                )

            end

        end

    end


    TireWearManager.log(
        "VehicleTypes | Wheels=%d hinzugefuegt=%d vorhanden=%d Fehler=%d",
        wheelTypes,
        added,
        existing,
        failed
    )


    return failed == 0

end

function TireWearManager.start()

    TireWearManager.log(
        "Manager gestartet"
    )


    if not TireWearManager.registerSpecialization() then

        Logging.error(
            "[RealTireWear] Abbruch: Specialization Registrierung fehlgeschlagen"
        )

        return

    end


    local success =
        TireWearManager.registerVehicleTypes()


    if success then

        TireWearManager.log(
            "Manager Registrierung abgeschlossen"
        )

    else

        Logging.warning(
            "[RealTireWear] Manager Registrierung mit Fehlern abgeschlossen"
        )

    end

end

TireWearManager.start()
