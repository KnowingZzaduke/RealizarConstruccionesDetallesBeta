local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- 🔗 CONEXIÓN
-- ==========================================
local Connections = ReplicatedStorage:WaitForChild("Connections")
local Remotes = Connections:WaitForChild("Remotes")
local PlotSystem = Remotes:WaitForChild("PlotSystem")

-- ==========================================
-- ⚙️ CONFIGURACIÓN
-- ==========================================
local CARPETA_PRINCIPAL = "MisConstruccionesRoblox" 
local RADIO_HORIZONTAL = 45 -- Radio alrededor del centro
local ALTURA_MAXIMA = 900   -- Altura hacia el cielo (Rascacielos)

if not isfolder(CARPETA_PRINCIPAL) then makefolder(CARPETA_PRINCIPAL) end

local datosGuardados = {} 
local bloqueSeleccionado = nil 
local procesoActivo = false

-- Herramienta
local tool = Instance.new("Tool")
tool.RequiresHandle = false
tool.Name = "📐 Replicador v18 (Exacto)"
tool.Parent = LocalPlayer.Backpack

-- Selección Visual
local highlightBox = Instance.new("SelectionBox")
highlightBox.Color3 = Color3.fromRGB(255, 170, 0)
highlightBox.LineThickness = 0.05
highlightBox.Parent = workspace
highlightBox.Adornee = nil

-- ==========================================
-- 🖥️ GUI SIMPLIFICADA
-- ==========================================
if CoreGui:FindFirstChild("ClonadorProGUI") then CoreGui.ClonadorProGUI:Destroy() end
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClonadorProGUI"
if syn and syn.protect_gui then syn.protect_gui(screenGui) elseif gethui then screenGui.Parent = gethui() else screenGui.Parent = CoreGui end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 220, 0, 320) 
mainFrame.Position = UDim2.new(0.02, 0, 0.35, 0) 
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame)

local title = Instance.new("TextLabel")
title.Text = "🏗️ REPLICADOR v18"
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 170, 0)
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local nameInput = Instance.new("TextBox")
nameInput.PlaceholderText = "Nombre archivo..."
nameInput.Size = UDim2.new(0.7, 0, 0, 30)
nameInput.Position = UDim2.new(0.05, 0, 0.12, 0)
nameInput.Parent = mainFrame

local btnSave = Instance.new("TextButton")
btnSave.Text = "💾"
btnSave.Size = UDim2.new(0.2, 0, 0, 30)
btnSave.Position = UDim2.new(0.75, 0, 0.12, 0)
btnSave.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
btnSave.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Text = "Listo."
statusLabel.Size = UDim2.new(1,0,0,20)
statusLabel.Position = UDim2.new(0,0,0.9,0)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.new(0.8,0.8,0.8)
statusLabel.Parent = mainFrame

function notificar(texto)
    statusLabel.Text = texto
    game:GetService("StarterGui"):SetCore("SendNotification", {Title="v18", Text=texto, Duration=2})
end

-- ==========================================
-- 🧬 LÓGICA DE DETECCIÓN EXACTA (CLAVE)
-- ==========================================

function obtenerNombreRealDelBloque(parte)
    -- Aquí está la magia. Tus logs muestran "part_cube_neon", "wedge_tile", etc.
    -- Estos nombres suelen estar en el MODELO padre de la parte física.
    
    if parte.Parent and parte.Parent:IsA("Model") then
        local nombreModelo = parte.Parent.Name
        
        -- Filtros de seguridad para no copiar cosas del sistema
        if nombreModelo ~= "Model" and nombreModelo ~= "Folder" then
            return nombreModelo -- Retorna "part_cube_glass", "wedge_wood", etc.
        end
    end
    
    return "part_cube" -- Fallback si no encuentra nombre específico
end

function esBloqueValido(parte, centroCFrame)
    if not parte:IsA("BasePart") then return false end
    if parte.Name == "Baseplate" or parte.Transparency == 1 then return false end
    if parte.Name:find("Ghost") then return false end
    if parte.Parent:FindFirstChild("Humanoid") then return false end -- No copiar jugadores

    local posParte = parte.Position
    local posCentro = centroCFrame.Position
    
    -- Distancia Horizontal (Cilindro)
    local distH = (Vector3.new(posParte.X, 0, posParte.Z) - Vector3.new(posCentro.X, 0, posCentro.Z)).Magnitude
    -- Distancia Vertical (Altura Infinita)
    local distV = posParte.Y - posCentro.Y
    
    if distH <= RADIO_HORIZONTAL and distV >= -2 and distV <= ALTURA_MAXIMA then
        return true
    end
    return false
end

function copiarEstructura()
    if not bloqueSeleccionado then return notificar("⚠️ Selecciona el bloque base") end
    
    datosGuardados = {}
    local origen = bloqueSeleccionado.CFrame
    local count = 0
    
    -- Visualizador Amarillo
    local visual = Instance.new("Part")
    visual.Shape = Enum.PartType.Cylinder
    visual.Size = Vector3.new(1, RADIO_HORIZONTAL*2, RADIO_HORIZONTAL*2) 
    visual.CFrame = origen * CFrame.Angles(0,0,math.rad(90)) + Vector3.new(0, 10, 0)
    visual.Transparency = 0.9; visual.Color = Color3.fromRGB(255, 255, 0)
    visual.Anchored = true; visual.CanCollide = false; visual.Parent = workspace
    Debris:AddItem(visual, 2)

    notificar("🔍 Escaneando tipos de bloques...")

    for _, p in pairs(workspace:GetDescendants()) do
        if esBloqueValido(p, origen) and p ~= visual then
            local rel = origen:Inverse() * p.CFrame
            
            -- CAPTURAMOS EL NOMBRE EXACTO (Ej: "wedge_tile")
            local tipoExacto = obtenerNombreRealDelBloque(p)
            
            table.insert(datosGuardados, {
                Type = tipoExacto,  -- Guardamos el tipo específico
                Size = {p.Size.X, p.Size.Y, p.Size.Z},
                CF = {rel:GetComponents()}
            })
            count = count + 1
        end
    end
    notificar("✅ Copiados: " .. count .. " elementos")
end

-- ==========================================
-- 🔨 LÓGICA DE CONSTRUCCIÓN EXACTA
-- ==========================================

function encontrarBloqueYSuID(posicionCFrame)
    local partesCercanas = workspace:GetPartBoundsInRadius(posicionCFrame.Position, 0.8) -- Radio ajustado
    for _, parte in pairs(partesCercanas) do
        if parte:IsA("BasePart") and parte.Name ~= "Baseplate" then
            local modeloPadre = parte.Parent
            if modeloPadre then
                -- Buscamos el UUID en el Modelo Padre
                local id = modeloPadre:GetAttribute("Id") or modeloPadre:GetAttribute("ID")
                if id then return parte, id end
            end
        end
    end
    return nil, nil
end

function redondearCFrame(cf)
    local x, y, z = cf.X, cf.Y, cf.Z
    -- Redondeo suave para evitar errores de coma flotante
    return CFrame.new(x, y, z) * (cf - cf.Position)
end

function construirReal()
    if #datosGuardados == 0 then return notificar("⚠️ Archivo vacío") end
    if not bloqueSeleccionado then return notificar("⚠️ Selecciona dónde construir") end

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    procesoActivo = true
    notificar("🔨 Replicando Estructura...")
    
    local nuevoCentro = bloqueSeleccionado.CFrame + Vector3.new(0,1,0)
    local posOriginal = hrp.CFrame
    hrp.Anchored = true

    for i, data in pairs(datosGuardados) do
        if not procesoActivo then break end

        -- 1. Calcular Posición
        local relCF = CFrame.new(unpack(data.CF))
        local cframeFinal = nuevoCentro * relCF
        cframeFinal = redondearCFrame(cframeFinal)
        local sizeObjetivo = Vector3.new(unpack(data.Size))
        local nombreBloque = data.Type -- Aquí usamos "wedge_tile", "part_water", etc.

        -- 2. Teleport
        hrp.CFrame = cframeFinal * CFrame.new(0, 5, 0)
        RunService.Heartbeat:Wait()

        -- 3. COLOCAR (Usando el nombre exacto capturado)
        -- Ejemplo log: PlaceFurniture, "wedge_tile", CFrame...
        PlotSystem:InvokeServer("placeFurniture", nombreBloque, cframeFinal)

        -- 4. ESPERAR Y ESCALAR
        local parteFisica = nil
        local idEncontrado = nil
        local intentos = 0
        
        while not idEncontrado and intentos < 15 do
            task.wait(0.1)
            parteFisica, idEncontrado = encontrarBloqueYSuID(cframeFinal)
            intentos = intentos + 1
        end

        if idEncontrado then
            -- 5. ESCALAR (Usando el UUID generado)
            -- Ejemplo log: ScaleFurniture, "uuid", CFrame, Vector3(size)
            PlotSystem:InvokeServer("scaleFurniture", idEncontrado, cframeFinal, sizeObjetivo)
            
            -- Feedback Visual
            if parteFisica then
                local b = Instance.new("SelectionBox", parteFisica)
                b.Color3 = Color3.fromRGB(255, 170, 0)
                b.Adornee = parteFisica; Debris:AddItem(b, 0.3)
            end
        else
            warn("❌ No apareció: " .. nombreBloque)
        end
        
        task.wait(0.1) -- Pequeña pausa para no saturar
    end

    hrp.Anchored = false
    hrp.CFrame = posOriginal
    procesoActivo = false
    notificar("✅ Construcción Completada")
end

-- ==========================================
-- BOTONES
-- ==========================================
btnSave.MouseButton1Click:Connect(function()
    if #datosGuardados > 0 and nameInput.Text ~= "" then
        writefile(CARPETA_PRINCIPAL.."/"..nameInput.Text..".json", HttpService:JSONEncode(datosGuardados))
        notificar("Guardado")
    end
end)

local loadBtn = Instance.new("TextButton", mainFrame)
loadBtn.Text = "📂 Cargar Archivo"; loadBtn.Size = UDim2.new(0.9,0,0,30); loadBtn.Position = UDim2.new(0.05,0,0.25,0); loadBtn.BackgroundColor3 = Color3.fromRGB(50,50,55); loadBtn.TextColor3 = Color3.new(1,1,1)
loadBtn.MouseButton1Click:Connect(function()
    local files = listfiles(CARPETA_PRINCIPAL)
    if #files > 0 then
        datosGuardados = HttpService:JSONDecode(readfile(files[#files]))
        notificar("Cargado: " .. files[#files]:match("([^/]+)$"))
    end
end)

local btnCopia = Instance.new("TextButton", mainFrame); btnCopia.Text = "1. COPIAR (K)"; btnCopia.Size = UDim2.new(0.9,0,0,40); btnCopia.Position = UDim2.new(0.05,0,0.4,0); btnCopia.BackgroundColor3 = Color3.fromRGB(0,150,100); btnCopia.TextColor3 = Color3.new(1,1,1)
btnCopia.MouseButton1Click:Connect(copiarEstructura)

local btnBuild = Instance.new("TextButton", mainFrame); btnBuild.Text = "2. CONSTRUIR (B)"; btnBuild.Size = UDim2.new(0.9,0,0,40); btnBuild.Position = UDim2.new(0.05,0,0.55,0); btnBuild.BackgroundColor3 = Color3.fromRGB(200,100,0); btnBuild.TextColor3 = Color3.new(1,1,1)
btnBuild.MouseButton1Click:Connect(construirReal)

local btnStop = Instance.new("TextButton", mainFrame); btnStop.Text = "PARAR (X)"; btnStop.Size = UDim2.new(0.9,0,0,30); btnStop.Position = UDim2.new(0.05,0,0.7,0); btnStop.BackgroundColor3 = Color3.fromRGB(150,0,0); btnStop.TextColor3 = Color3.new(1,1,1)
btnStop.MouseButton1Click:Connect(function() procesoActivo = false end)

tool.Equipped:Connect(function(m)
    m.Button1Down:Connect(function() 
        if m.Target then 
            bloqueSeleccionado = m.Target
            highlightBox.Adornee = m.Target
            notificar("Centro: " .. m.Target.Name)
        end 
    end)
    m.KeyDown:Connect(function(k) 
        if k=="k" then copiarEstructura() elseif k=="b" then construirReal() elseif k=="x" then procesoActivo=false end 
    end)
end)
tool.Unequipped:Connect(function() highlightBox.Adornee = nil end)
notificar("v18 Lista para replicar materiales.")
