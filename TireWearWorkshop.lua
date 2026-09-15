-- ============================================================
-- FS25_RealTireWearWorkshop.lua
-- by Marcus (Cobra Modding)
--
--
-- Version 1.0.0.0
--
--
-- Keine Änderung am Skript ohne meine Erlaubnis.
-- ============================================================

TireWearWorkshop = {}
TireWearDisplay = {}

TireWearServiceGuiElement = {}

local TireWearServiceGuiElement_mt =
    Class(
        TireWearServiceGuiElement,
        GuiElement
    )


function TireWearServiceGuiElement.new(target)

    local self =
        GuiElement.new(
            target,
            TireWearServiceGuiElement_mt
        )

    self:setPosition(
        0,
        0
    )

    self:setSize(
        1,
        1
    )

    self:setVisible(
        false
    )

    return self

end


function TireWearServiceGuiElement:draw(
    clipX1,
    clipY1,
    clipX2,
    clipY2
)

    GuiElement.draw(
        self,
        clipX1,
        clipY1,
        clipX2,
        clipY2
    )

end


function TireWearServiceGuiElement:mouseEvent(
    posX,
    posY,
    isDown,
    isUp,
    button,
    eventUsed
)

    if not self.visible
        or TireWearWorkshop == nil
        or TireWearWorkshop.serviceOpen ~= true then

        return eventUsed or false

    end


    TireWearDisplay.handleMouseEvent(
        posX,
        posY,
        isDown,
        isUp,
        button
    )


    return true

end


function TireWearDisplay.createGuiElement(screen)

    if GuiElement == nil then
        return nil
    end


    return TireWearServiceGuiElement.new(
        screen
    )

end

TireWearDisplay.PANEL_X =
    0.275

TireWearDisplay.PANEL_Y =
    0.225

TireWearDisplay.PANEL_WIDTH =
    0.450

TireWearDisplay.PANEL_HEIGHT =
    0.500


TireWearDisplay.PADDING =
    0.018

TireWearDisplay.HEADER_HEIGHT =
    0.086

TireWearDisplay.CARD_GAP =
    0.014

TireWearDisplay.CARD_HEIGHT =
    0.275

TireWearDisplay.BOTTOM_HEIGHT =
    0.105


TireWearDisplay.BUTTON_HEIGHT =
    0.048

TireWearDisplay.BUTTON_PADDING =
    0.008

TireWearDisplay.TEXT_TITLE =
    0.0190

TireWearDisplay.TEXT_SUBTITLE =
    0.0105

TireWearDisplay.TEXT_STATUS_LABEL =
    0.0085

TireWearDisplay.TEXT_STATUS =
    0.0140

TireWearDisplay.TEXT_AXLE =
    0.0120

TireWearDisplay.TEXT_ROW =
    0.0098

TireWearDisplay.TEXT_VALUE =
    0.0098

TireWearDisplay.TEXT_BUTTON =
    0.0094

TireWearDisplay.TEXT_SMALL =
    0.0086


TireWearDisplay.BAR_HEIGHT =
    0.0080

TireWearDisplay.COLOR_PANEL = {
    0.025,
    0.030,
    0.029,
    1.00
}


TireWearDisplay.COLOR_HEADER = {
    0.055,
    0.063,
    0.061,
    1.00
}


TireWearDisplay.COLOR_CARD = {
    0.040,
    0.047,
    0.045,
    1.00
}


TireWearDisplay.COLOR_CARD_LINE = {
    0.26,
    0.29,
    0.28,
    1.00
}


TireWearDisplay.COLOR_TEXT = {
    1.00,
    1.00,
    1.00,
    1.00
}


TireWearDisplay.COLOR_TEXT_MUTED = {
    0.88,
    0.90,
    0.89,
    1.00
}


TireWearDisplay.COLOR_HINT = {
    0.70,
    0.73,
    0.72,
    1.00
}


TireWearDisplay.COLOR_ACCENT = {
    0.52,
    0.82,
    0.12,
    1.00
}


TireWearDisplay.COLOR_ACCENT_HOVER = {
    0.68,
    0.96,
    0.20,
    1.00
}


TireWearDisplay.COLOR_BUTTON = {
    0.16,
    0.24,
    0.11,
    1.00
}


TireWearDisplay.COLOR_BUTTON_HOVER = {
    0.28,
    0.43,
    0.15,
    1.00
}


TireWearDisplay.COLOR_BUTTON_DISABLED = {
    0.075,
    0.082,
    0.080,
    1.00
}


TireWearDisplay.COLOR_BAR_BACKGROUND = {
    0.105,
    0.125,
    0.120,
    1.00
}


TireWearDisplay.COLOR_GOOD = {
    0.58,
    0.90,
    0.25,
    1.00
}


TireWearDisplay.COLOR_MEDIUM = {
    0.98,
    0.72,
    0.12,
    1.00
}


TireWearDisplay.COLOR_BAD = {
    0.96,
    0.20,
    0.15,
    1.00
}


TireWearDisplay.mouseX =
    -1

TireWearDisplay.mouseY =
    -1


TireWearDisplay.hitBoxes = {}

function TireWearDisplay.clamp(
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


function TireWearDisplay.getNumber(
    value,
    defaultValue
)

    local number =
        tonumber(value)

    if number == nil then
        return defaultValue or 0
    end

    return number

end


function TireWearDisplay.hasTireWear(vehicle)

    return vehicle ~= nil
        and vehicle.spec_tireWear ~= nil
        and vehicle.spec_tireWear.wheels ~= nil
        and #TireReplaceEvent.getServiceUnits(vehicle, TireReplaceEvent.MODE_ALL) > 0

end


function TireWearDisplay.getWorkshopVehicle()

    if TireWearWorkshop == nil
        or TireWearWorkshop.isWorkshopOpen ~= true
        or TireWearWorkshop.serviceOpen ~= true then

        return nil

    end


    if g_workshopScreen == nil then
        return nil
    end


    return g_workshopScreen.vehicle

end


function TireWearDisplay.getVehicleName(vehicle)

    if vehicle ~= nil
        and vehicle.getName ~= nil then

        local name =
            vehicle:getName()

        if name ~= nil
            and name ~= "" then

            return string.upper(name)

        end

    end


    return "FAHRZEUG"

end

function TireWearDisplay.isInsidePanel(
    posX,
    posY
)

    return
        posX >= TireWearDisplay.PANEL_X
        and posX <=
            TireWearDisplay.PANEL_X
            +
            TireWearDisplay.PANEL_WIDTH

        and posY >= TireWearDisplay.PANEL_Y
        and posY <=
            TireWearDisplay.PANEL_Y
            +
            TireWearDisplay.PANEL_HEIGHT

end

function TireWearDisplay.setHitBox(
    name,
    x,
    y,
    width,
    height,
    enabled,
    mode
)

    TireWearDisplay.hitBoxes[name] = {
        x = x,
        y = y,
        width = width,
        height = height,
        enabled = enabled ~= false,
        mode = mode
    }

end


function TireWearDisplay.isInside(
    posX,
    posY,
    box
)

    if box == nil then
        return false
    end


    return posX >= box.x
        and posX <= box.x + box.width
        and posY >= box.y
        and posY <= box.y + box.height

end


function TireWearDisplay.isHovered(name)

    return TireWearDisplay.isInside(
        TireWearDisplay.mouseX,
        TireWearDisplay.mouseY,
        TireWearDisplay.hitBoxes[name]
    )

end


function TireWearDisplay.getLeftMouseButton()

    if Input ~= nil
        and Input.MOUSE_BUTTON_LEFT ~= nil then

        return Input.MOUSE_BUTTON_LEFT

    end


    return 1

end

function TireWearDisplay.handleMouseEvent(
    posX,
    posY,
    isDown,
    isUp,
    button
)

    TireWearDisplay.mouseX =
        posX

    TireWearDisplay.mouseY =
        posY


    if button ~=
        TireWearDisplay.getLeftMouseButton() then

        return true

    end


    if not isUp then
        return true
    end

    if not TireWearDisplay.isInsidePanel(
        posX,
        posY
    ) then

        if TireWearWorkshop ~= nil
            and TireWearWorkshop.onClickCloseService ~= nil then

            TireWearWorkshop.onClickCloseService()

        end

        return true

    end

    for _, axle in ipairs(TireWearDisplay.serviceAxles or {}) do
        local hitBox = TireWearDisplay.hitBoxes["axle_" .. axle.mode]
        if hitBox ~= nil and hitBox.enabled
            and TireWearDisplay.isInside(posX, posY, hitBox) then
            TireWearWorkshop.onClickReplaceMode(axle.mode)
            return true
        end
    end

    local allBox =
        TireWearDisplay.hitBoxes.all


    if allBox ~= nil
        and allBox.enabled
        and TireWearDisplay.isInside(
            posX,
            posY,
            allBox
        ) then

        TireWearWorkshop.onClickReplaceAll()

        return true

    end


    return true

end

function TireWearDisplay.getWearColor(
    wear,
    damaged
)


    wear =
        TireWearDisplay.clamp(
            wear,
            0,
            1
        )


    if damaged then return TireWearDisplay.COLOR_BAD end

    if wear < 0.50 then

        return TireWearDisplay.COLOR_GOOD

    elseif wear < 0.80 then

        return TireWearDisplay.COLOR_MEDIUM

    end


    return TireWearDisplay.COLOR_BAD

end


function TireWearDisplay.setTextColorFromTable(color)

    setTextColor(
        color[1],
        color[2],
        color[3],
        color[4]
    )

end

function TireWearDisplay.drawRect(
    x,
    y,
    width,
    height,
    color
)

    drawFilledRect(
        x,
        y,
        width,
        height,
        color[1],
        color[2],
        color[3],
        color[4]
    )

end


function TireWearDisplay.drawLine(
    x,
    y,
    width,
    color
)

    TireWearDisplay.drawRect(
        x,
        y,
        width,
        0.0012,
        color
    )

end


function TireWearDisplay.drawWearBar(
    x,
    y,
    width,
    wear,
    damaged
)

    wear =
        TireWearDisplay.clamp(
            wear,
            0,
            1
        )


    TireWearDisplay.drawRect(
        x,
        y,
        width,
        TireWearDisplay.BAR_HEIGHT,
        TireWearDisplay.COLOR_BAR_BACKGROUND
    )


    if wear > 0 then

        TireWearDisplay.drawRect(
            x,
            y,
            width * wear,
            TireWearDisplay.BAR_HEIGHT,
            TireWearDisplay.getWearColor(
                wear,
                damaged
            )
        )

    end

end

function TireWearDisplay.getAxleIndices(
    vehicle,
    mode
)

    if TireReplaceEvent == nil
        or TireReplaceEvent.getServiceUnits == nil then

        return {}

    end


    return TireReplaceEvent.getServiceUnits(
        vehicle,
        mode
    )

end


function TireWearDisplay.isCrawlerVehicle(
    vehicle
)

    return TireReplaceEvent ~= nil
        and TireReplaceEvent.isCrawlerServiceVehicle ~= nil
        and TireReplaceEvent.isCrawlerServiceVehicle(
            vehicle
        )

end


function TireWearDisplay.getServicePlural(
    vehicle
)

    if TireWearDisplay.isCrawlerVehicle(
        vehicle
    ) then

        return "Bandlaufwerke"

    end


    return "Reifen"

end


function TireWearDisplay.sortLeftRight(
    vehicle,
    units
)

    local result = {}


    if vehicle == nil
        or vehicle.spec_tireWear == nil
        or vehicle.spec_tireWear.wheels == nil then

        return result

    end


    for _, unit in ipairs(
        units
    ) do

        local wear = 0
        local damaged = false


        if TireReplaceEvent ~= nil
            and TireReplaceEvent.getServiceUnitState ~= nil then

            wear,
            damaged =
                TireReplaceEvent.getServiceUnitState(
                    vehicle,
                    unit
                )

        end


        local representativeIndex =
            unit.representativeIndex
            or (
                unit.indices ~= nil
                and unit.indices[1]
            )
            or 0


        result[#result + 1] = {
            index = representativeIndex,
            unit = unit,
            tire = {
                wear = wear,
                damaged = damaged
            },
            isCrawler = unit.isCrawler == true,
            isLeft = unit.isLeft == true,
            hasSide = unit.hasSide == true
        }

    end


    table.sort(
        result,
        function(a, b)

            if a.hasSide
                and b.hasSide
                and a.isLeft ~= b.isLeft then

                return a.isLeft == true

            end


            return a.index < b.index

        end
    )


    return result

end


function TireWearDisplay.getAxleSummary(
    vehicle,
    mode
)

    if TireReplaceEvent == nil
        or TireReplaceEvent.getTireData == nil then

        return 0,
               0,
               0,
               0,
               false

    end


    local averageWear,
          damagedCount,
          tireCount =
        TireReplaceEvent.getTireData(
            vehicle,
            mode
        )


    local price =
        0


    if TireReplaceEvent.getPrice ~= nil then

        price =
            TireReplaceEvent.getPrice(
                vehicle,
                mode
            )

    end


    local needsReplacement =
        false


    if TireReplaceEvent.needsReplacement ~= nil then

        needsReplacement =
            TireReplaceEvent.needsReplacement(
                vehicle,
                mode
            )

    end


    return averageWear,
           damagedCount,
           tireCount,
           price,
           needsReplacement

end

function TireWearDisplay.drawWheelRow(
    tire,
    label,
    x,
    y,
    width
)

    if tire == nil then
        return
    end


    local wear =
        TireWearDisplay.clamp(
            TireWearDisplay.getNumber(
                tire.wear,
                0
            ),
            0,
            1
        )


    local damaged =
        tire.damaged == true


    local color =
        TireWearDisplay.getWearColor(
            wear,
            damaged
        )


    setTextAlignment(
        RenderText.ALIGN_LEFT
    )

    setTextBold(
        false
    )

    TireWearDisplay.setTextColorFromTable(
        TireWearDisplay.COLOR_TEXT_MUTED
    )


    renderText(
        x,
        y,
        TireWearDisplay.TEXT_ROW,
        label
    )


    local barX =
        x + width * 0.25


    local barWidth =
        width * 0.51


    TireWearDisplay.drawWearBar(
        barX,
        y + 0.0015,
        barWidth,
        wear,
        damaged
    )


    setTextAlignment(
        RenderText.ALIGN_RIGHT
    )

    TireWearDisplay.setTextColorFromTable(
        color
    )

    setTextBold(
        false
    )


    renderText(
        x + width,
        y,
        TireWearDisplay.TEXT_VALUE,
        damaged and "PLATT" or string.format("%.0f%%", wear * 100)
    )


    setTextBold(
        false
    )

end

function TireWearDisplay.drawButton(
    name,
    text,
    x,
    y,
    width,
    height,
    enabled,
    mode
)

    TireWearDisplay.setHitBox(
        name,
        x,
        y,
        width,
        height,
        enabled,
        mode
    )


    local hovered =
        enabled
        and TireWearDisplay.isHovered(name)


    local background


    if not enabled then

        background =
            TireWearDisplay.COLOR_BUTTON_DISABLED

    elseif hovered then

        background =
            TireWearDisplay.COLOR_BUTTON_HOVER

    else

        background =
            TireWearDisplay.COLOR_BUTTON

    end


    TireWearDisplay.drawRect(
        x,
        y,
        width,
        height,
        background
    )


    local accentColor =
        hovered
        and TireWearDisplay.COLOR_ACCENT_HOVER
        or TireWearDisplay.COLOR_ACCENT


    TireWearDisplay.drawRect(
        x,
        y,
        0.003,
        height,
        enabled
            and accentColor
            or TireWearDisplay.COLOR_CARD_LINE
    )


    setTextAlignment(
        RenderText.ALIGN_CENTER
    )

    setTextBold(
        true
    )

    TireWearDisplay.setTextColorFromTable(
        enabled
            and TireWearDisplay.COLOR_TEXT
            or TireWearDisplay.COLOR_TEXT_MUTED
    )


    renderText(
        x + width * 0.5,
        y + height * 0.32,
        TireWearDisplay.TEXT_BUTTON,
        text
    )


    setTextBold(
        false
    )

end

function TireWearDisplay.drawAxleCard(
    vehicle,
    mode,
    title,
    buttonName,
    buttonText,
    x,
    y,
    width,
    height
)

    TireWearDisplay.drawRect(
        x,
        y,
        width,
        height,
        TireWearDisplay.COLOR_CARD
    )


    TireWearDisplay.drawRect(
        x,
        y + height - 0.004,
        width,
        0.004,
        TireWearDisplay.COLOR_ACCENT
    )


    local averageWear,
          damagedCount,
          tireCount,
          price,
          needsReplacement =
        TireWearDisplay.getAxleSummary(
            vehicle,
            mode
        )


    local averageColor =
        TireWearDisplay.getWearColor(
            averageWear,
            damagedCount > 0
        )


    setTextAlignment(
        RenderText.ALIGN_LEFT
    )

    setTextBold(
        true
    )

    TireWearDisplay.setTextColorFromTable(
        TireWearDisplay.COLOR_TEXT
    )


    renderText(
        x + 0.012,
        y + height - 0.034,
        math.min(TireWearDisplay.TEXT_AXLE, (width - 0.040) / math.max(#title * 0.65, 1)),
        title
    )


    setTextAlignment(
        RenderText.ALIGN_RIGHT
    )

    TireWearDisplay.setTextColorFromTable(
        averageColor
    )


    renderText(
        x + width - 0.012,
        y + height - 0.034,
        TireWearDisplay.TEXT_AXLE,
        string.format(
            "%.0f%%",
            averageWear * 100
        )
    )


    TireWearDisplay.drawLine(
        x + 0.012,
        y + height - 0.047,
        width - 0.024,
        TireWearDisplay.COLOR_CARD_LINE
    )


    local sorted =
        TireWearDisplay.sortLeftRight(
            vehicle,
            TireWearDisplay.getAxleIndices(
                vehicle,
                mode
            )
        )


    local rowY =
        y + height - 0.080


    for rowIndex, item in ipairs(sorted) do

        local label


        if item.hasSide then

            label =
                item.isLeft
                and "Links"
                or "Rechts"

        else

            label =
                string.format(
                    "%s %d",
                    item.isCrawler
                        and "Bandlaufwerk"
                        or "Reifen",
                    item.index
                )

        end


        TireWearDisplay.drawWheelRow(
            item.tire,
            label,
            x + 0.012,
            rowY,
            width - 0.024
        )


        rowY =
            rowY - 0.030


        if rowIndex >= 4 then
            break
        end

    end


    local buttonX =
        x + TireWearDisplay.BUTTON_PADDING


    local buttonY =
        y + TireWearDisplay.BUTTON_PADDING


    local buttonWidth =
        width
        -
        TireWearDisplay.BUTTON_PADDING * 2


    local finalText =
        buttonText


    if needsReplacement
        and price > 0 then

        finalText =
            string.format(
                "%s · %s",
                buttonText,
                TireWearWorkshop.formatMoney(
                    price
                )
            )

    elseif not needsReplacement then

        finalText =
            "KEIN WECHSEL NOETIG"

    end


    TireWearDisplay.drawButton(
        buttonName,
        finalText,
        buttonX,
        buttonY,
        buttonWidth,
        TireWearDisplay.BUTTON_HEIGHT,
        needsReplacement,
        mode
    )


    setTextAlignment(
        RenderText.ALIGN_LEFT
    )

    setTextBold(
        false
    )

    TireWearDisplay.setTextColorFromTable(
        TireWearDisplay.COLOR_TEXT_MUTED
    )


    renderText(
        x + 0.012,
        buttonY
        +
        TireWearDisplay.BUTTON_HEIGHT
        +
        0.011,
        TireWearDisplay.TEXT_SMALL,
        string.format(
            "%d %s",
            tireCount,
            TireWearDisplay.getServicePlural(
                vehicle
            )
        )
    )

end

function TireWearDisplay.renderServicePanel()

    TireWearDisplay.hitBoxes = {}


    local vehicle =
        TireWearDisplay.getWorkshopVehicle()


    if not TireWearDisplay.hasTireWear(
        vehicle
    ) then

        return

    end

    local x =
        TireWearDisplay.PANEL_X

    local y =
        TireWearDisplay.PANEL_Y

    local width =
        TireWearDisplay.PANEL_WIDTH

    local height =
        TireWearDisplay.PANEL_HEIGHT

    TireWearDisplay.drawRect(
        x,
        y,
        width,
        height,
        TireWearDisplay.COLOR_PANEL
    )


    TireWearDisplay.drawRect(
        x,
        y,
        0.004,
        height,
        TireWearDisplay.COLOR_ACCENT
    )

    local headerY =
        y
        +
        height
        -
        TireWearDisplay.HEADER_HEIGHT


    TireWearDisplay.drawRect(
        x + 0.004,
        headerY,
        width - 0.004,
        TireWearDisplay.HEADER_HEIGHT,
        TireWearDisplay.COLOR_HEADER
    )


    TireWearDisplay.drawRect(
        x + 0.004,
        headerY,
        width - 0.004,
        0.003,
        TireWearDisplay.COLOR_ACCENT
    )

    setTextAlignment(
        RenderText.ALIGN_LEFT
    )

    setTextBold(
        true
    )

    TireWearDisplay.setTextColorFromTable(
        TireWearDisplay.COLOR_TEXT
    )


    renderText(
        x + TireWearDisplay.PADDING,
        headerY + 0.046,
        TireWearDisplay.TEXT_TITLE,
        "REIFENSERVICE"
    )


    setTextBold(
        false
    )

    TireWearDisplay.setTextColorFromTable(
        TireWearDisplay.COLOR_TEXT_MUTED
    )


    renderText(
        x + TireWearDisplay.PADDING,
        headerY + 0.023,
        TireWearDisplay.TEXT_SUBTITLE,
        TireWearDisplay.getVehicleName(
            vehicle
        )
    )


    TireWearDisplay.setTextColorFromTable(
        TireWearDisplay.COLOR_HINT
    )


    renderText(
        x + TireWearDisplay.PADDING,
        headerY + 0.008,
        TireWearDisplay.TEXT_SMALL,
        "Außerhalb klicken zum Schließen"
    )

    local averageWear,
          damagedCount,
          totalCount,
          allPrice,
          allNeedsReplacement =
        TireWearDisplay.getAxleSummary(
            vehicle,
            TireReplaceEvent.MODE_ALL
        )


    local statusColor =
        TireWearDisplay.getWearColor(
            averageWear,
            damagedCount > 0
        )


    setTextAlignment(
        RenderText.ALIGN_RIGHT
    )

    setTextBold(
        false
    )

    TireWearDisplay.setTextColorFromTable(
        TireWearDisplay.COLOR_TEXT_MUTED
    )


    renderText(
        x
        +
        width
        -
        TireWearDisplay.PADDING,
        headerY + 0.049,
        TireWearDisplay.TEXT_STATUS_LABEL,
        "GESAMTVERSCHLEISS"
    )


    setTextBold(
        true
    )

    TireWearDisplay.setTextColorFromTable(
        statusColor
    )


    renderText(
        x
        +
        width
        -
        TireWearDisplay.PADDING,
        headerY + 0.024,
        TireWearDisplay.TEXT_STATUS,
        string.format(
            "%.0f%%",
            averageWear * 100
        )
    )

    local flatCount, tireCount = TireWear.getFlatTireCount(vehicle)
    setTextBold(false)
    TireWearDisplay.setTextColorFromTable(flatCount > 0 and statusColor or TireWearDisplay.COLOR_TEXT_MUTED)
    renderText(x + width - TireWearDisplay.PADDING, headerY + 0.008,
        TireWearDisplay.TEXT_SMALL,
        string.format("%d / %d Reifen kaputt%s", flatCount, tireCount,
            flatCount > 0 and " | Max. 15 km/h" or ""))

    local axles = TireReplaceEvent.getServiceAxles(vehicle)
    TireWearDisplay.serviceAxles = axles
    TireWearDisplay.hitBoxes = {}
    local count = math.max(#axles, 1)
    local cardWidth = (width - TireWearDisplay.PADDING * 2
        - TireWearDisplay.CARD_GAP * (count - 1)) / count
    local cardY = y + TireWearDisplay.BOTTOM_HEIGHT
    for index, axle in ipairs(axles) do
        local cardX = x + TireWearDisplay.PADDING
            + (index - 1) * (cardWidth + TireWearDisplay.CARD_GAP)
        TireWearDisplay.drawAxleCard(vehicle, axle.mode, axle.title,
            "axle_" .. axle.mode, count >= 3 and "ERSETZEN" or axle.title .. " ERSETZEN",
            cardX, cardY, cardWidth, TireWearDisplay.CARD_HEIGHT)
    end

    local allButtonX =
        x
        +
        TireWearDisplay.PADDING


    local allButtonY =
        y
        +
        0.025


    local allButtonWidth =
        width
        -
        TireWearDisplay.PADDING * 2


    local allText


    local servicePlural =
        TireWearDisplay.getServicePlural(
            vehicle
        )


    if allNeedsReplacement
        and allPrice > 0 then

        allText =
            string.format(
                "ALLE %s ERSETZEN · %s",
                string.upper(
                    servicePlural
                ),
                TireWearWorkshop.formatMoney(
                    allPrice
                )
            )

    else

        allText =
            string.format(
                "ALLE %s · KEIN WECHSEL NOETIG",
                string.upper(
                    servicePlural
                )
            )

    end


    TireWearDisplay.drawButton(
        "all",
        allText,
        allButtonX,
        allButtonY,
        allButtonWidth,
        TireWearDisplay.BUTTON_HEIGHT,
        allNeedsReplacement,
        TireReplaceEvent.MODE_ALL
    )


    setTextAlignment(
        RenderText.ALIGN_LEFT
    )

    setTextBold(
        false
    )

    TireWearDisplay.setTextColorFromTable(
        TireWearDisplay.COLOR_TEXT_MUTED
    )


    renderText(
        allButtonX,
        allButtonY
        +
        TireWearDisplay.BUTTON_HEIGHT
        +
        0.012,
        TireWearDisplay.TEXT_SMALL,
        string.format(
            "Gesamt: %d %s",
            totalCount,
            servicePlural
        )
    )


    setTextAlignment(
        RenderText.ALIGN_LEFT
    )

    setTextBold(
        false
    )

    setTextColor(
        1,
        1,
        1,
        1
    )

end

TireWearWorkshop.isWorkshopOpen = false
TireWearWorkshop.serviceOpen = false

TireWearWorkshop.serviceButton = nil
TireWearWorkshop.serviceGuiElement = nil

TireWearWorkshop.hooksInstalled = false
TireWearWorkshop.guiDrawHookInstalled = false
TireWearWorkshop.screenReRegistered = false

TireWearWorkshop.lastVehicle = nil

TireWearWorkshop.serviceActionEventId = nil

TireWearWorkshop.SERVICE_BUTTON_MIN_WIDTH =
    0.102

TireWearWorkshop.lastButtonLayoutSignature =
    nil


TireWearWorkshop.layoutRefreshPending =
    false

function TireWearWorkshop.log(
    text,
    ...
)
end

function TireWearWorkshop.getScreen()

    return g_workshopScreen

end


function TireWearWorkshop.getVehicle()

    local screen =
        TireWearWorkshop.getScreen()


    if screen == nil then
        return nil
    end


    return screen.vehicle

end


function TireWearWorkshop.hasTireWear(
    vehicle
)

    return vehicle ~= nil
        and vehicle.spec_tireWear ~= nil
        and vehicle.spec_tireWear.wheels ~= nil
        and #TireReplaceEvent.getServiceUnits(vehicle, TireReplaceEvent.MODE_ALL) > 0

end

function TireWearWorkshop.formatMoney(
    value
)

    value =
        math.max(
            0,
            math.floor(
                (
                    tonumber(
                        value
                    )
                    or 0
                )
                +
                0.5
            )
        )


    if g_i18n ~= nil
        and g_i18n.formatMoney ~= nil then

        return g_i18n:formatMoney(
            value,
            0,
            true
        )

    end


    return string.format(
        "%d €",
        value
    )

end


function TireWearWorkshop.getFarmMoney(
    vehicle
)

    if vehicle == nil
        or vehicle.getOwnerFarmId == nil
        or g_farmManager == nil then

        return nil

    end


    local farmId =
        vehicle:getOwnerFarmId()


    if farmId == nil then
        return nil
    end


    local farm =
        g_farmManager:getFarmById(
            farmId
        )


    if farm == nil then
        return nil
    end


    return tonumber(
        farm.money
    )

end


function TireWearWorkshop.getModeName(
    mode
)

    if TireReplaceEvent ~= nil
        and mode == TireReplaceEvent.MODE_FRONT then

        return "Vorderachse"

    elseif TireReplaceEvent ~= nil
        and mode == TireReplaceEvent.MODE_REAR then

        return "Hinterachse"

    end


    if TireReplaceEvent ~= nil and type(mode) == "number"
        and mode > TireReplaceEvent.MODE_AXLE_BASE then
        local vehicle = TireWearDisplay.getWorkshopVehicle()
        if vehicle ~= nil then
            for _, axle in ipairs(TireReplaceEvent.getServiceAxles(vehicle)) do
                if axle.mode == mode then return axle.title end
            end
        end
        return string.format("Achse %d", mode - TireReplaceEvent.MODE_AXLE_BASE)
    end

    return "Alle Reifen"

end

function TireWearWorkshop.setButtonVisible(
    button,
    visible
)

    if button == nil then
        return
    end


    if button.setVisible ~= nil then

        button:setVisible(
            visible
        )

    else

        button.visible =
            visible

    end

end


function TireWearWorkshop.setButtonDisabled(
    button,
    disabled
)

    if button == nil then
        return
    end


    if button.setDisabled ~= nil then

        button:setDisabled(
            disabled
        )

    else

        button.disabled =
            disabled

    end

end


function TireWearWorkshop.setButtonText(
    button,
    text
)

    if button == nil then
        return
    end


    if button.setText ~= nil then

        button:setText(
            text
        )

    else

        button.text =
            text

        button.sourceText =
            text

    end

end


function TireWearWorkshop.updateButtonLayout()

    local screen =
        TireWearWorkshop.getScreen()


    if screen == nil
        or screen.buttonsBox == nil then

        return

    end


    if screen.buttonsBox.updateLayoutCells ~= nil then

        screen.buttonsBox:updateLayoutCells(
            false
        )

    end

end

function TireWearWorkshop.getButtonWidth(
    button
)

    if button == nil then
        return nil
    end


    if button.size ~= nil
        and tonumber(
            button.size[1]
        ) ~= nil then

        return tonumber(
            button.size[1]
        )

    end


    if tonumber(
        button.width
    ) ~= nil then

        return tonumber(
            button.width
        )

    end


    return nil

end


function TireWearWorkshop.getButtonHeight(
    button
)

    if button == nil then
        return nil
    end


    if button.size ~= nil
        and tonumber(
            button.size[2]
        ) ~= nil then

        return tonumber(
            button.size[2]
        )

    end


    if tonumber(
        button.height
    ) ~= nil then

        return tonumber(
            button.height
        )

    end


    return nil

end


function TireWearWorkshop.setButtonSize(
    button,
    width,
    height
)

    if button == nil then
        return
    end


    width =
        tonumber(
            width
        )


    height =
        tonumber(
            height
        )


    if width == nil
        or width <= 0 then

        return

    end


    if height == nil
        or height <= 0 then

        height =
            0.025

    end


    if button.setSize ~= nil then

        button:setSize(
            width,
            height
        )

    else

        button.size =
            button.size
            or {}


        button.size[1] =
            width


        button.size[2] =
            height


        button.width =
            width


        button.height =
            height

    end

end

function TireWearWorkshop.getButtonText(
    button
)

    if button == nil then
        return ""
    end


    if button.getText ~= nil then

        local text =
            button:getText()


        if text ~= nil then

            return tostring(
                text
            )

        end

    end


    if button.text ~= nil then

        return tostring(
            button.text
        )

    end


    if button.sourceText ~= nil then

        return tostring(
            button.sourceText
        )

    end


    return ""

end

function TireWearWorkshop.getButtonLayoutSignature()

    local screen =
        TireWearWorkshop.getScreen()


    if screen == nil
        or screen.buttonsBox == nil
        or screen.buttonsBox.elements == nil then

        return nil

    end


    local parts = {}


    for index,
        element in ipairs(
            screen.buttonsBox.elements
        ) do

        if element ~= nil
            and element ~= TireWearWorkshop.serviceButton then

            local visible =
                element.visible ~= false


            local text =
                TireWearWorkshop.getButtonText(
                    element
                )


            local width =
                TireWearWorkshop.getButtonWidth(
                    element
                )
                or 0


            table.insert(
                parts,
                string.format(
                    "%d:%s:%s:%.6f",
                    index,
                    tostring(
                        visible
                    ),
                    text,
                    width
                )
            )

        end

    end


    return table.concat(
        parts,
        "|"
    )

end

function TireWearWorkshop.setupServiceButtonInput(
    button
)

    if button == nil then
        return false
    end


    if InputAction == nil
        or InputAction.RTW_TIRE_SERVICE == nil then

        Logging.warning(
            "[RealTireWear] RTW_TIRE_SERVICE ist nicht registriert"
        )

        return false

    end

    if button.setInputAction ~= nil then

        button:setInputAction(
            "RTW_TIRE_SERVICE"
        )

    else

        button.inputActionName =
            "RTW_TIRE_SERVICE"

    end

    button.hideKeyboardGlyph =
        false


    button.hasLoadedInputGlyph =
        false

    button.isTriggerableByGlobalAction =
        false


    return true

end

function TireWearWorkshop.ensureServiceButtonSeparator(
    button
)

    if button == nil
        or BitmapElement == nil then

        return
    end

    if button.elements ~= nil then

        for _,
            element in ipairs(
                button.elements
            ) do

            if element ~= nil
                and element.name == "realTireWearSeparator" then

                return

            end

        end

    end

    local separator =
        BitmapElement.new(
            button
        )


    if separator == nil then
        return
    end


    separator.name =
        "realTireWearSeparator"


    button:addElement(
        separator
    )


    if separator.applyProfile ~= nil then

        separator:applyProfile(
            "fs25_buttonBoxSeparator"
        )

    end

end

function TireWearWorkshop.applyServiceButtonWidth()

    local button =
        TireWearWorkshop.serviceButton


    if button == nil then
        return false
    end


    local width =
        TireWearWorkshop.SERVICE_BUTTON_MIN_WIDTH


    local currentWidth =
        TireWearWorkshop.getButtonWidth(
            button
        )


    if currentWidth ~= nil then

        width =
            math.max(
                width,
                currentWidth
            )

    end


    local height =
        TireWearWorkshop.getButtonHeight(
            button
        )


    if height == nil
        or height <= 0 then

        height =
            0.025

    end


    TireWearWorkshop.setButtonSize(
        button,
        width,
        height
    )


    return true,
           width

end

function TireWearWorkshop.createServiceButton(
    screen
)

    if screen == nil
        or screen.buttonsBox == nil
        or ButtonElement == nil then

        return false

    end

    if screen.realTireWearServiceButton ~= nil then

        TireWearWorkshop.serviceButton =
            screen.realTireWearServiceButton


        TireWearWorkshop.ensureServiceButtonSeparator(
            TireWearWorkshop.serviceButton
        )


        return true

    end

    local button =
        ButtonElement.new(
            screen.buttonsBox
        )


    if button == nil then

        Logging.warning(
            "[RealTireWear] Reifenservice-Button konnte nicht erstellt werden"
        )

        return false

    end


    button.name =
        "realTireWearServiceButton"


    button.id =
        "realTireWearServiceButton"


    screen.buttonsBox:addElement(
        button
    )

    if button.applyProfile ~= nil then

        button:applyProfile(
            "buttonActivate"
        )

    end

    TireWearWorkshop.setButtonText(
        button,
        "REIFENSERVICE"
    )

    TireWearWorkshop.setupServiceButtonInput(
        button
    )

    TireWearWorkshop.ensureServiceButtonSeparator(
        button
    )

    button.onClickCallback =
        function()

            return TireWearWorkshop.onClickToggleService()

        end

    if button.updateSize ~= nil then

        button:updateSize()

    end


    screen.realTireWearServiceButton =
        button


    TireWearWorkshop.serviceButton =
        button

    local _,
          width =
        TireWearWorkshop.applyServiceButtonWidth()

    TireWearWorkshop.updateButtonLayout()


    TireWearWorkshop.lastButtonLayoutSignature =
        TireWearWorkshop.getButtonLayoutSignature()


    TireWearWorkshop.log(
        "Reifenservice-Button erstellt | Breite=%s",
        tostring(
            width
        )
    )


    return true

end

function TireWearWorkshop.refreshServiceButtonLayout()

    local screen =
        TireWearWorkshop.getScreen()


    local button =
        TireWearWorkshop.serviceButton


    if screen == nil
        or screen.buttonsBox == nil
        or button == nil then

        return false

    end


    local box =
        screen.buttonsBox

    TireWearWorkshop.setButtonText(
        button,
        "REIFENSERVICE"
    )

    TireWearWorkshop.setupServiceButtonInput(
        button
    )

    TireWearWorkshop.ensureServiceButtonSeparator(
        button
    )

    if button.updateSize ~= nil then

        button:updateSize()

    end

    local _,
          width =
        TireWearWorkshop.applyServiceButtonWidth()

    if box.updateLayoutCells ~= nil then

        box:updateLayoutCells(
            false
        )

    end


    TireWearWorkshop.lastButtonLayoutSignature =
        TireWearWorkshop.getButtonLayoutSignature()


    TireWearWorkshop.layoutRefreshPending =
        false


    TireWearWorkshop.log(
        "Reifenservice Buttonlayout aktualisiert | Breite=%s",
        tostring(
            width
        )
    )


    return true

end

function TireWearWorkshop.createServiceGuiElement(
    screen
)

    if screen == nil then
        return false
    end


    if screen.realTireWearServiceGuiElement ~= nil then

        TireWearWorkshop.serviceGuiElement =
            screen.realTireWearServiceGuiElement


        return true

    end


    if TireWearDisplay == nil
        or TireWearDisplay.createGuiElement == nil then

        return false

    end


    local element =
        TireWearDisplay.createGuiElement(
            screen
        )


    if element == nil then
        return false
    end


    screen:addElement(
        element
    )


    screen.realTireWearServiceGuiElement =
        element


    TireWearWorkshop.serviceGuiElement =
        element


    if element.setVisible ~= nil then

        element:setVisible(
            false
        )

    else

        element.visible =
            false

    end


    TireWearWorkshop.log(
        "Modales Reifenservice-Eingabeelement erstellt"
    )


    return true

end

function TireWearWorkshop.updateServiceButton(
    forceLayout
)

    local vehicle =
        TireWearWorkshop.getVehicle()


    local hasTires =
        TireWearWorkshop.hasTireWear(
            vehicle
        )


    if TireWearWorkshop.serviceButton ~= nil then

        local visible =
            hasTires
            and not TireWearWorkshop.serviceOpen


        TireWearWorkshop.setButtonVisible(
            TireWearWorkshop.serviceButton,
            visible
        )


        TireWearWorkshop.setButtonDisabled(
            TireWearWorkshop.serviceButton,
            not hasTires
        )

    end


    if forceLayout == true then

        TireWearWorkshop.refreshServiceButtonLayout()

    end

end

function TireWearWorkshop.setServiceOpen(
    state
)

    state =
        state == true


    local vehicle =
        TireWearWorkshop.getVehicle()


    if state
        and not TireWearWorkshop.hasTireWear(
            vehicle
        ) then

        state =
            false

    end


    if TireWearWorkshop.serviceOpen == state then

        return

    end


    TireWearWorkshop.serviceOpen =
        state


    local screen =
        TireWearWorkshop.getScreen()


    if screen ~= nil then

        TireWearWorkshop.createServiceGuiElement(
            screen
        )

    end


    local element =
        TireWearWorkshop.serviceGuiElement


    if element ~= nil then

        if state
            and screen ~= nil
            and screen.addElement ~= nil then

            screen:addElement(
                element
            )

        end


        if element.setVisible ~= nil then

            element:setVisible(
                state
            )

        else

            element.visible =
                state

        end

    end


    TireWearWorkshop.updateServiceButton(
        true
    )


    if state then

        TireWearWorkshop.log(
            "Reifenservice geoeffnet"
        )

    else

        TireWearWorkshop.log(
            "Reifenservice geschlossen"
        )

    end

end


function TireWearWorkshop.onClickToggleService()

    TireWearWorkshop.setServiceOpen(
        not TireWearWorkshop.serviceOpen
    )


    return true

end


function TireWearWorkshop.onClickCloseService()

    TireWearWorkshop.setServiceOpen(
        false
    )


    return true

end

function TireWearWorkshop.onClickReplaceMode(
    mode
)

    local vehicle =
        TireWearWorkshop.getVehicle()


    if not TireWearWorkshop.hasTireWear(
        vehicle
    ) then

        return true

    end


    if TireReplaceEvent == nil
        or TireReplaceEvent.needsReplacement == nil
        or TireReplaceEvent.getPrice == nil
        or TireReplaceEvent.getTireData == nil then

        Logging.warning(
            "[RealTireWear] TireReplaceEvent nicht vollstaendig verfuegbar"
        )


        return true

    end


    if not TireReplaceEvent.needsReplacement(
        vehicle,
        mode
    ) then

        return true

    end


    local price =
        TireReplaceEvent.getPrice(
            vehicle,
            mode
        )


    if price <= 0 then

        Logging.warning(
            "[RealTireWear] Reifenwechselpreis ungueltig"
        )


        return true

    end


    local farmMoney =
        TireWearWorkshop.getFarmMoney(
            vehicle
        )


    if farmMoney ~= nil
        and farmMoney < price then

        if InfoDialog ~= nil
            and InfoDialog.show ~= nil then

            InfoDialog.show(
                string.format(
                    "Nicht genug Geld fuer den Reifenwechsel.\n\nKosten: %s\nKontostand: %s",
                    TireWearWorkshop.formatMoney(
                        price
                    ),
                    TireWearWorkshop.formatMoney(
                        farmMoney
                    )
                )
            )

        end


        return true

    end


    local vehicleName =
        "Fahrzeug"


    if vehicle.getName ~= nil then

        vehicleName =
            vehicle:getName()
            or vehicleName

    end


    local averageWear,
          damagedCount,
          tireCount =
        TireReplaceEvent.getTireData(
            vehicle,
            mode
        )


    local servicePlural =
        TireWearDisplay ~= nil
        and TireWearDisplay.getServicePlural ~= nil
        and TireWearDisplay.getServicePlural(
            vehicle
        )
        or "Reifen"


    local message =
        string.format(
            "%s\n\n%s ersetzen?\n\n%s: %d\nDurchschnittlicher Verschleiss: %.0f%%\nKosten: %s",
            vehicleName,
            TireWearWorkshop.getModeName(
                mode
            ),
            servicePlural,
            tireCount,
            averageWear * 100,
            TireWearWorkshop.formatMoney(
                price
            )
        )




    local callback =
        function(
            yes
        )

            if not yes then
                return
            end


            local currentVehicle =
                TireWearWorkshop.getVehicle()


            if currentVehicle ~= vehicle then

                TireWearWorkshop.log(
                    "Reifenwechsel abgebrochen: Fahrzeug geaendert"
                )


                return

            end


            if TireReplaceEvent.sendEvent ~= nil then

                TireReplaceEvent.sendEvent(
                    vehicle,
                    mode
                )

            else

                Logging.warning(
                    "[RealTireWear] TireReplaceEvent.sendEvent fehlt"
                )

            end

        end


    if YesNoDialog ~= nil
        and YesNoDialog.show ~= nil then

        YesNoDialog.show(
            callback,
            nil,
            message
        )

    else

        Logging.warning(
            "[RealTireWear] YesNoDialog nicht verfuegbar"
        )

    end


    return true

end


function TireWearWorkshop.onClickReplaceFront()

    if TireReplaceEvent == nil then
        return true
    end


    return TireWearWorkshop.onClickReplaceMode(
        TireReplaceEvent.MODE_FRONT
    )

end


function TireWearWorkshop.onClickReplaceRear()

    if TireReplaceEvent == nil then
        return true
    end


    return TireWearWorkshop.onClickReplaceMode(
        TireReplaceEvent.MODE_REAR
    )

end


function TireWearWorkshop.onClickReplaceAll()

    if TireReplaceEvent == nil then
        return true
    end


    return TireWearWorkshop.onClickReplaceMode(
        TireReplaceEvent.MODE_ALL
    )

end

function TireWearWorkshop.onGuiDraw(
    gui
)

    if not TireWearWorkshop.isWorkshopOpen then
        return
    end


    if not TireWearWorkshop.serviceOpen then
        return
    end


    if gui ~= nil
        and gui.dialogs ~= nil
        and #gui.dialogs > 0 then

        return

    end


    if TireWearDisplay == nil
        or TireWearDisplay.renderServicePanel == nil then

        return

    end


    if new2DLayer ~= nil then

        new2DLayer()

    end


    TireWearDisplay.renderServicePanel()

end

function TireWearWorkshop.onGuiMouseEvent(gui, superFunc, posX, posY, isDown, isUp, button)
    if TireWearWorkshop.isWorkshopOpen and TireWearWorkshop.serviceOpen
        and (gui.dialogs == nil or #gui.dialogs == 0) then
        TireWearDisplay.handleMouseEvent(posX, posY, isDown, isUp, button)
        return true
    end
    return superFunc(gui, posX, posY, isDown, isUp, button)
end

function TireWearWorkshop.installGuiDrawHook()

    if TireWearWorkshop.guiDrawHookInstalled then
        return
    end


    if Gui == nil
        or Gui.draw == nil
        or Utils == nil then

        return

    end


    if Gui.mouseEvent ~= nil then
        Gui.mouseEvent = Utils.overwrittenFunction(
            Gui.mouseEvent, TireWearWorkshop.onGuiMouseEvent
        )
    end

    Gui.draw =
        Utils.appendedFunction(
            Gui.draw,
            TireWearWorkshop.onGuiDraw
        )


    TireWearWorkshop.guiDrawHookInstalled =
        true


    TireWearWorkshop.log(
        "Globaler GUI-Draw-Hook registriert"
    )

end

function TireWearWorkshop.onServiceAction(
    actionName,
    inputValue,
    callbackState,
    isAnalog
)

    if not TireWearWorkshop.isWorkshopOpen then
        return
    end


    if TireWearWorkshop.serviceOpen then
        return
    end


    local vehicle =
        TireWearWorkshop.getVehicle()


    if not TireWearWorkshop.hasTireWear(
        vehicle
    ) then

        return
    end


    TireWearWorkshop.log(
        "RTW_TIRE_SERVICE ausgeloest"
    )


    TireWearWorkshop.setServiceOpen(
        true
    )

end


function TireWearWorkshop.unregisterServiceAction()

    if g_inputBinding ~= nil
        and TireWearWorkshop.serviceActionEventId ~= nil then

        g_inputBinding:removeActionEvent(
            TireWearWorkshop.serviceActionEventId
        )

    end


    TireWearWorkshop.serviceActionEventId =
        nil

end


function TireWearWorkshop.registerServiceAction()

    if g_inputBinding == nil then

        Logging.warning(
            "[RealTireWear] g_inputBinding nicht vorhanden"
        )

        return false

    end


    if InputAction == nil
        or InputAction.RTW_TIRE_SERVICE == nil then

        Logging.warning(
            "[RealTireWear] InputAction.RTW_TIRE_SERVICE nicht vorhanden"
        )

        return false

    end


    TireWearWorkshop.unregisterServiceAction()


    local success,
          eventId =
        g_inputBinding:registerActionEvent(
            InputAction.RTW_TIRE_SERVICE,
            TireWearWorkshop,
            TireWearWorkshop.onServiceAction,
            false,
            true,
            false,
            true
        )


    TireWearWorkshop.serviceActionEventId =
        eventId


    TireWearWorkshop.log(
        "RTW_TIRE_SERVICE registriert | success=%s | eventId=%s",
        tostring(
            success
        ),
        tostring(
            eventId
        )
    )


    if eventId ~= nil
        and g_inputBinding.setActionEventTextVisibility ~= nil then

        g_inputBinding:setActionEventTextVisibility(
            eventId,
            false
        )

    end


    return eventId ~= nil

end

function TireWearWorkshop.onWorkshopOpen(
    screen
)

    TireWearWorkshop.isWorkshopOpen =
        true


    TireWearWorkshop.serviceOpen =
        false


    TireWearWorkshop.lastVehicle =
        screen ~= nil
        and screen.vehicle
        or nil


    TireWearWorkshop.createServiceButton(
        screen
    )


    TireWearWorkshop.createServiceGuiElement(
        screen
    )


    TireWearWorkshop.registerServiceAction()


    TireWearWorkshop.updateServiceButton(
        false
    )


    TireWearWorkshop.refreshServiceButtonLayout()


    TireWearWorkshop.log(
        "WorkshopScreen geoeffnet"
    )

end


function TireWearWorkshop.onWorkshopClose(
    screen
)

    TireWearWorkshop.serviceOpen =
        false


    if TireWearWorkshop.serviceGuiElement ~= nil then

        if TireWearWorkshop.serviceGuiElement.setVisible ~= nil then

            TireWearWorkshop.serviceGuiElement:setVisible(
                false
            )

        else

            TireWearWorkshop.serviceGuiElement.visible =
                false

        end

    end


    TireWearWorkshop.unregisterServiceAction()


    TireWearWorkshop.isWorkshopOpen =
        false


    TireWearWorkshop.lastVehicle =
        nil


    TireWearWorkshop.lastButtonLayoutSignature =
        nil


    TireWearWorkshop.layoutRefreshPending =
        false


    TireWearWorkshop.log(
        "WorkshopScreen geschlossen"
    )

end


function TireWearWorkshop.onWorkshopSetVehicle(
    screen,
    vehicle
)

    if not TireWearWorkshop.isWorkshopOpen then
        return
    end


    TireWearWorkshop.lastVehicle =
        vehicle


    if not TireWearWorkshop.hasTireWear(
        vehicle
    ) then

        if TireWearWorkshop.serviceOpen then

            TireWearWorkshop.serviceOpen =
                false


            if TireWearWorkshop.serviceGuiElement ~= nil then

                if TireWearWorkshop.serviceGuiElement.setVisible ~= nil then

                    TireWearWorkshop.serviceGuiElement:setVisible(
                        false
                    )

                else

                    TireWearWorkshop.serviceGuiElement.visible =
                        false

                end

            end

        end

    end


    TireWearWorkshop.updateServiceButton(
        false
    )


    TireWearWorkshop.refreshServiceButtonLayout()


    TireWearWorkshop.log(
        "Workshop Fahrzeug aktualisiert - Buttonlayout erneuert"
    )

end


function TireWearWorkshop.installHooks()

    if TireWearWorkshop.hooksInstalled then
        return
    end


    if WorkshopScreen == nil
        or Utils == nil then

        return

    end


    if WorkshopScreen.onOpen ~= nil then

        WorkshopScreen.onOpen =
            Utils.appendedFunction(
                WorkshopScreen.onOpen,
                TireWearWorkshop.onWorkshopOpen
            )

    end


    if WorkshopScreen.onClose ~= nil then

        WorkshopScreen.onClose =
            Utils.appendedFunction(
                WorkshopScreen.onClose,
                TireWearWorkshop.onWorkshopClose
            )

    end


    if WorkshopScreen.setVehicle ~= nil then

        WorkshopScreen.setVehicle =
            Utils.appendedFunction(
                WorkshopScreen.setVehicle,
                TireWearWorkshop.onWorkshopSetVehicle
            )

    end


    TireWearWorkshop.hooksInstalled =
        true


    TireWearWorkshop.log(
        "Workshop-Hooks registriert"
    )

end

function TireWearWorkshop.reRegisterScreen()

    if TireWearWorkshop.screenReRegistered then
        return
    end


    if g_workshopScreen == nil
        or WorkshopScreen == nil
        or WorkshopScreen.createFromExistingGui == nil then

        return

    end


    g_workshopScreen =
        WorkshopScreen.createFromExistingGui(
            g_workshopScreen,
            "WorkshopScreen"
        )


    TireWearWorkshop.screenReRegistered =
        true


    TireWearWorkshop.log(
        "WorkshopScreen aus bestehender GUI neu registriert"
    )

end

function TireWearWorkshop:loadMap(
    mapName
)

    TireWearWorkshop.installHooks()

    TireWearWorkshop.installGuiDrawHook()

    TireWearWorkshop.reRegisterScreen()


    TireWearWorkshop.log(
        "Workshop Listener geladen"
    )

end


function TireWearWorkshop:deleteMap()

    TireWearWorkshop.unregisterServiceAction()


    TireWearWorkshop.serviceOpen =
        false


    TireWearWorkshop.isWorkshopOpen =
        false


    TireWearWorkshop.serviceButton =
        nil


    TireWearWorkshop.serviceGuiElement =
        nil


    TireWearWorkshop.lastVehicle =
        nil


    TireWearWorkshop.lastButtonLayoutSignature =
        nil


    TireWearWorkshop.layoutRefreshPending =
        false

end

function TireWearWorkshop:update(
    dt
)

    if not TireWearWorkshop.screenReRegistered then

        TireWearWorkshop.reRegisterScreen()

    end


    if not TireWearWorkshop.guiDrawHookInstalled then

        TireWearWorkshop.installGuiDrawHook()

    end


    if not TireWearWorkshop.isWorkshopOpen then
        return
    end


    local screen =
        TireWearWorkshop.getScreen()


    if screen == nil then
        return
    end

    if TireWearWorkshop.serviceButton == nil then

        if TireWearWorkshop.createServiceButton(
            screen
        ) then

            TireWearWorkshop.updateServiceButton(
                false
            )


            TireWearWorkshop.refreshServiceButtonLayout()

        end

    end

    if TireWearWorkshop.serviceGuiElement == nil then

        TireWearWorkshop.createServiceGuiElement(
            screen
        )

    end

    local signature =
        TireWearWorkshop.getButtonLayoutSignature()


    if signature ~= nil then

        if TireWearWorkshop.lastButtonLayoutSignature == nil then

            TireWearWorkshop.lastButtonLayoutSignature =
                signature

        elseif signature
            ~=
            TireWearWorkshop.lastButtonLayoutSignature then

            TireWearWorkshop.lastButtonLayoutSignature =
                signature


            TireWearWorkshop.layoutRefreshPending =
                true

        end

    end

    if TireWearWorkshop.layoutRefreshPending then

        TireWearWorkshop.refreshServiceButtonLayout()

    end

end


function TireWearWorkshop:draw()
end


function TireWearWorkshop:keyEvent(
    unicode,
    sym,
    modifier,
    isDown
)

end


function TireWearWorkshop:mouseEvent(
    posX,
    posY,
    isDown,
    isUp,
    button
)
end

TireWearWorkshop.installHooks()

TireWearWorkshop.installGuiDrawHook()

TireWearWorkshop.reRegisterScreen()


addModEventListener(
    TireWearWorkshop
)
