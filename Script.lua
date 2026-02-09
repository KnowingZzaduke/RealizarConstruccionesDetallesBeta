local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ==========================================
-- 🔗 CONEXIÓN
-- ==========================================
local Connections = ReplicatedStorage:WaitForChild("Connections")
local Remotes = Connections:WaitForChild("Remotes")
local PlotSystem = Remotes:WaitForChild("PlotSystem")

-- ==========================================
-- ⚙️ CONFIGURACIÓN V66 (SKIP MODE)
-- ==========================================
local CARPETA_PRINCIPAL = "MisConstruccionesRoblox"
local SNAP_GRID = 0.05       
local OFFSET_ALTURA = 0.1    
local INTENTOS_MAXIMOS = 2   -- Reducido: si falla 2 veces, se rinde y sigue
local VELOCIDAD_VUELO = 350

-- 🔥 LISTA NEGRA: Objetos que el script IGNORARÁ COMPLETAMENTE
-- Escribe aquí los nombres exactos o partes del nombre que dan problemas.
local LISTA_NEGRA = {
    "LETRERO",
    "SIGN",
    "TEXT",
    "CARTEL",
    "Gamepass", -- Por si acaso
    "VIP"
}

if not isfolder(CARPETA_PRINCIPAL) then makefolder(CARPETA_PRINCIPAL) end

local datosGuardados = {}
local bloqueSeleccionado = nil
local procesoActivo = false

local tool = Instance.new("Tool")
tool.RequiresHandle = false
tool.Name = "📐 V66 (Skip Fix)"
tool.Parent = LocalPlayer.Backpack

local highlightBox = Instance.new("SelectionBox")
highlightBox.Color3 = Color3.fromRGB(255, 0, 0)
highlightBox.LineThickness = 0.05
highlightBox.Parent = workspace
highlightBox.Adornee = nil

-- ==========================================
-- 🖥️ GUI
-- ==========================================
if CoreGui:FindFirstChild("ClonadorProGUI") then CoreGui.ClonadorProGUI:Destroy() end
local screenGui = Instance.new("ScreenGui"); screenGui.Name = "ClonadorProGUI"; if syn and syn.protect_gui then syn.protect_gui(screenGui) elseif gethui then screenGui.Parent = gethui() else screenGui.Parent = CoreGui end
local mainFrame = Instance.new("Frame"); mainFrame.Size = UDim2.new(0, 220, 0, 100); mainFrame.Position = UDim2.new(0.5, -110, 0.85, 0); mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30); mainFrame.Parent = screenGui; Instance.new("UICorner", mainFrame)
local statusLabel = Instance.new("TextLabel"); statusLabel.Size = UDim2.new(1,0,1,0); statusLabel.BackgroundTransparency=1; statusLabel.TextColor3 = Color3.new(1,1,1); statusLabel.TextSize=14; statusLabel.Parent = mainFrame
function notificar(t) statusLabel.Text = t end

-- ==========================================
-- 🧠 FUNCIONES DE AYUDA
-- ==========================================

function redondear(num)
    return math.floor(num / SNAP_GRID + 0.5) * SNAP_GRID
end

function limpiarCFrame(cf)
    local x, y, z = redondear(cf.X), redondear(cf.Y), redondear(cf.Z)
    local rx, ry, rz = cf:ToEulerAnglesYXZ()
    local snapAngle = math.rad(90)
    local ry_clean = math.floor(ry / snapAngle + 0.5) * snapAngle
    return CFrame.new(x, y, z) * CFrame.Angles(0, ry_clean, 0)
end

function obtenerNombreReal(parte)
    local modelo = parte.Parent
    if not modelo then return "part_cube" end
    local atts = {"ItemId", "FurnitureId", "ID", "id", "ItemName"}
    for _, att in pairs(atts) do
        local val = modelo:GetAttribute(att)
        if val and typeof(val) == "string" then return val end
    end
    if modelo:IsA("Model") and modelo.Name ~= "Model" then return modelo.Name end
    return "part_cube"
end

function encontrarBloqueYSuID(posicionCFrame)
    local RADIO = 3.0 
    local partes = workspace:GetPartBoundsInRadius(posicionCFrame.Position, RADIO)
    for _, parte in pairs(partes) do
        if parte:IsA("BasePart") and parte.Name ~= "Baseplate" and not parte.Name:find("Ghost") and parte.Transparency < 1 then
            local modelo = parte.Parent
            if modelo then
                local id = modelo:GetAttribute("Id") or modelo:GetAttribute("ID") or modelo:GetAttribute("FurnitureId")
                if id then return parte, id end
            end
        end
    end
    return nil, nil
end

-- 🔥 FUNCIÓN DE FILTRADO
function esObjetoProhibido(nombre)
    local nombreMayus = string.upper(nombre)
    for _, prohibido in pairs(LISTA_NEGRA) do
        if string.find(nombreMayus, string.upper(prohibido)) then
            return true
        end
    end
    return false
end

-- ==========================================
-- 🏗️ CONSTRUCCIÓN V66 (CON PROTECCIÓN)
-- ==========================================
function construirV66()
    if not bloqueSeleccionado or #datosGuardados == 0 then return notificar("⚠️ Faltan datos") end
    
    local hrp = LocalPlayer.Character.HumanoidRootPart
    local ry_player = select(2, hrp.CFrame:ToEulerAnglesYXZ())
    local rotacionBase = CFrame.Angles(0, math.floor(ry_player / math.rad(90) + 0.5) * math.rad(90), 0)
    local centroBase = bloqueSeleccionado.CFrame * CFrame.new(0, bloqueSeleccionado.Size.Y/2, 0)
    centroBase = CFrame.new(centroBase.Position) * rotacionBase 
    
    procesoActivo = true
    hrp.Anchored = true
    notificar("🚀 Construyendo (Saltando Letreros)...")

    table.sort(datosGuardados, function(a, b) 
        if math.abs(a.CF[2] - b.CF[2]) > 0.5 then return a.CF[2] < b.CF[2] end
        return (a.Size[1]*a.Size[3]) > (b.Size[1]*b.Size[3]) 
    end)

    for i, data in pairs(datosGuardados) do
        if not procesoActivo then break end
        
        local nombreBloque = data.Type

        -- 🛑 1. CHECK DE LISTA NEGRA
        if esObjetoProhibido(nombreBloque) then
            warn("🚫 SALTO INTELIGENTE: Ignorando objeto prohibido [" .. nombreBloque .. "]")
            notificar("🚫 Saltando: " .. nombreBloque)
            task.wait(0.05) -- Pequeña pausa para no saturar
            continue -- SALTA AL SIGUIENTE OBJETO INMEDIATAMENTE
        end

        local relCF = CFrame.new(unpack(data.CF))
        local cfFinalBruto = centroBase * relCF
        local cframeObjetivo = limpiarCFrame(cfFinalBruto) + Vector3.new(0, OFFSET_ALTURA, 0)
        local sizeObjetivo = Vector3.new(unpack(data.Size))
        
        -- Mover jugador
        hrp.CFrame = CFrame.new(cframeObjetivo.Position + Vector3.new(0, 15, 0))
        task.wait(0.05)

        local idConfirmada = nil
        local intentos = 0
        
        while not idConfirmada and intentos < INTENTOS_MAXIMOS do
            local cfIntento = cframeObjetivo + Vector3.new(0, intentos * 0.2, 0)
            
            local _, check = encontrarBloqueYSuID(cfIntento)
            if check then idConfirmada = check; break end

            -- 🛑 2. PROTECCIÓN PCALL (EVITA CRASHEOS)
            local success, retorno = pcall(function()
                return PlotSystem:InvokeServer("placeFurniture", nombreBloque, cfIntento)
            end)
            
            if not success then
                warn("⚠️ Error del servidor al poner " .. nombreBloque .. ". Saltando...")
                break -- Rompe el while, va al siguiente objeto
            end

            if retorno then
                if typeof(retorno)=="string" then idConfirmada = retorno
                elseif typeof(retorno)=="Instance" then idConfirmada = retorno:GetAttribute("Id") end
            end
            
            if not idConfirmada then
                task.wait(0.2)
                _, idConfirmada = encontrarBloqueYSuID(cfIntento)
            end
            
            if not idConfirmada then intentos = intentos + 1 end
        end

        if idConfirmada then
            task.wait(0.1)
            pcall(function() -- Protegemos también el escalado
                PlotSystem:InvokeServer("scaleFurniture", idConfirmada, cframeObjetivo, sizeObjetivo)
                if intentos > 0 then
                     PlotSystem:InvokeServer("scaleFurniture", idConfirmada, cframeObjetivo - Vector3.new(0, intentos*0.2, 0), sizeObjetivo)
                end
            end)
        end
    end
    
    procesoActivo = false
    hrp.Anchored = false
    notificar("✅ Terminado")
end

-- ==========================================
-- 🎯 COPIAR V66
-- ==========================================
function copiarLimpio()
    if not bloqueSeleccionado then return notificar("⚠️ Selecciona Base") end
    datosGuardados = {}
    local cfBase = bloqueSeleccionado.CFrame * CFrame.new(0, bloqueSeleccionado.Size.Y/2, 0)
    local sizeBase = bloqueSeleccionado.Size
    local limX, limZ = sizeBase.X/2 + 0.5, sizeBase.Z/2 + 0.5 
    
    local c = 0
    for _, p in pairs(workspace:GetDescendants()) do
        if p:IsA("BasePart") and p~=bloqueSeleccionado and p.Name~="Baseplate" and not p.Name:find("Ghost") and p.Transparency<1 then
            local posRel = bloqueSeleccionado.CFrame:PointToObjectSpace(p.Position)
            if math.abs(posRel.X) <= limX and math.abs(posRel.Z) <= limZ and posRel.Y >= -1 then
                local nombreReal = obtenerNombreReal(p)
                
                -- Opcional: No guardamos letreros al copiar para ahorrar espacio
                if not esObjetoProhibido(nombreReal) then
                    local relCF = cfBase:Inverse() * p.CFrame
                    table.insert(datosGuardados, {
                        Type = nombreReal,
                        Size = {p.Size.X, p.Size.Y, p.Size.Z},
                        CF = {relCF:GetComponents()}
                    })
                    c=c+1
                end
            end
        end
    end
    notificar("✅ Copiado: " .. c .. " items (Limpios)")
    writefile(CARPETA_PRINCIPAL.."/temp_v66.json", HttpService:JSONEncode(datosGuardados))
end

tool.Equipped:Connect(function(m)
    m.Button1Down:Connect(function() if m.Target then bloqueSeleccionado=m.Target; highlightBox.Adornee=m.Target; notificar("Base: "..m.Target.Name) end end)
    m.KeyDown:Connect(function(k)
        if k=="k" then copiarLimpio()
        elseif k=="b" then 
            if isfile(CARPETA_PRINCIPAL.."/temp_v66.json") then
                datosGuardados=HttpService:JSONDecode(readfile(CARPETA_PRINCIPAL.."/temp_v66.json"))
                construirV66()
            end
        elseif k=="x" then procesoActivo=false
        end
    end)
end)
