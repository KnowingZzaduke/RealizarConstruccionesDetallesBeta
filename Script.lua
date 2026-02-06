local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ==========================================
-- 🔗 CONEXIÓN (SISTEMA CONSTRUCCIÓN)
-- ==========================================
local Connections = ReplicatedStorage:WaitForChild("Connections")
local Remotes = Connections:WaitForChild("Remotes")
local PlotSystem = Remotes:WaitForChild("PlotSystem")

-- ==========================================
-- ⚙️ CONFIGURACIÓN
-- ==========================================
local CARPETA_PRINCIPAL = "MisConstruccionesRoblox" 
local RADIO_HORIZONTAL = 45 -- Radio a los lados
local ALTURA_MAXIMA = 800   -- Altura hacia arriba (Rascacielos)
local NOMBRE_HERRAMIENTA_PINTURA = "PaintBucket" -- Nombre exacto de tu cubo de pintura

if not isfolder(CARPETA_PRINCIPAL) then makefolder(CARPETA_PRINCIPAL) end

local datosGuardados = {} 
local bloqueSeleccionado = nil 
local procesoActivo = false

-- Herramienta del Script
local tool = Instance.new("Tool")
tool.RequiresHandle = false
tool.Name = "📐 Arquitecto v17 (Pintor)"
tool.Parent = LocalPlayer.Backpack

-- Selección Visual
local highlightBox = Instance.new("SelectionBox")
highlightBox.Color3 = Color3.fromRGB(0, 255, 255)
highlightBox.LineThickness = 0.05
highlightBox.Parent = workspace
highlightBox.Adornee = nil

-- ==========================================
-- 🖥️ GUI (Optimizada)
-- ==========================================
if CoreGui:FindFirstChild("ClonadorProGUI") then CoreGui.ClonadorProGUI:Destroy() end
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClonadorProGUI"
if syn and syn.protect_gui then syn.protect_gui(screenGui) elseif gethui then screenGui.Parent = gethui() else screenGui.Parent = CoreGui end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 220, 0, 380) 
mainFrame.Position = UDim2.new(0.02, 0, 0.3, 0) 
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame)

local title = Instance.new("TextLabel")
title.Text = "🏗️ ARQUITECTO v17"
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(0, 255, 255)
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local nameInput = Instance.new("TextBox")
nameInput.PlaceholderText = "Nombre archivo..."
nameInput.Size = UDim2.new(0.7, 0, 0, 30)
nameInput.Position = UDim2.new(0.05, 0, 0.1, 0)
nameInput.Parent = mainFrame

local btnSave = Instance.new("TextButton")
btnSave.Text = "💾"
btnSave.Size = UDim2.new(0.2, 0, 0, 30)
btnSave.Position = UDim2.new(0.75, 0, 0.1, 0)
btnSave.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
btnSave.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Text = "Esperando..."
statusLabel.Size = UDim2.new(1,0,0,20)
statusLabel.Position = UDim2.new(0,0,0.92,0)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.new(1,1,1)
statusLabel.TextSize = 12
statusLabel.Parent = mainFrame

function notificar(texto)
    statusLabel.Text = texto
    game:GetService("StarterGui"):SetCore("SendNotification", {Title="v17", Text=texto, Duration=2})
end

-- ==========================================
-- 🧬 LÓGICA DE COPIA (SOPORTE RASCACIELOS)
-- ==========================================

function obtenerTipoBloque(parte)
    if parte.Parent and parte.Parent:IsA("Model") then
        return parte.Parent.Name
    end
    return "part_cube" 
end

function esBloqueValido(parte, centroCFrame)
    if not parte:IsA("BasePart") then return false end
    if parte.Name == "Baseplate" or parte.Transparency == 1 then return false end
    if parte.Name:find("Ghost") then return false end
    
    -- CÁLCULO CILÍNDRICO (Para copiar hacia arriba sin límite)
    local posParte = parte.Position
    local posCentro = centroCFrame.Position
    
    -- 1. Distancia Horizontal (Plana)
    local distH = (Vector3.new(posParte.X, 0, posParte.Z) - Vector3.new(posCentro.X, 0, posCentro.Z)).Magnitude
    
    -- 2. Distancia Vertical (Altura)
    local distV = posParte.Y - posCentro.Y
    
    -- Copiamos si está dentro del radio Y si está por encima del suelo (hasta 800 studs)
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
    
    -- Visualizador del Cilindro de Copia
    local visual = Instance.new("Part")
    visual.Shape = Enum.PartType.Cylinder
    visual.Size = Vector3.new(2, RADIO_HORIZONTAL*2, RADIO_HORIZONTAL*2) 
    visual.CFrame = origen * CFrame.Angles(0,0,math.rad(90)) + Vector3.new(0, 10, 0)
    visual.Transparency = 0.85
    visual.Color = Color3.fromRGB(255, 255, 0)
    visual.Anchored = true; visual.CanCollide = false; visual.Parent = workspace
    Debris:AddItem(visual, 3)

    notificar("🔍 Escaneando rascacielos...")

    for _, p in pairs(workspace:GetDescendants()) do
        if esBloqueValido(p, origen) and p ~= visual then
            local rel = origen:Inverse() * p.CFrame
            local tipo = obtenerTipoBloque(p)
            local color = {p.Color.R, p.Color.G, p.Color.B} -- Guardamos RGB
            
            table.insert(datosGuardados, {
                Name = tipo,
                Size = {p.Size.X, p.Size.Y, p.Size.Z},
                CF = {rel:GetComponents()},
                Color = color
            })
            count = count + 1
        end
    end
    notificar("✅ Copiados: " .. count .. " items")
end

-- ==========================================
-- 🎨 LÓGICA DE PINTURA (NUEVO)
-- ==========================================
function obtenerRemotoPintura()
    -- Buscamos el PaintBucket en el Character o en el Backpack
    local charTool = LocalPlayer.Character:FindFirstChild(NOMBRE_HERRAMIENTA_PINTURA)
    local backTool = LocalPlayer.Backpack:FindFirstChild(NOMBRE_HERRAMIENTA_PINTURA)
    
    local herramienta = charTool or backTool
    
    if herramienta then
        -- Ruta basada en tu Log: PaintBucket -> Remotes -> ServerControls
        local remotes = herramienta:FindFirstChild("Remotes")
        if remotes then
            return remotes:FindFirstChild("ServerControls")
        end
    end
    return nil
end

function pintarBloque(parteFisica, colorObj)
    local remotoPintura = obtenerRemotoPintura()
    
    if not remotoPintura then
        warn("⚠️ No se encontró el 'PaintBucket'. Asegúrate de tenerlo en el inventario.")
        return
    end
    
    -- Argumentos extraídos de tu Log del Spy Remote
    local args = {
        [1] = "PaintPart",
        [2] = {
            ["Part"] = parteFisica,
            ["Color"] = colorObj
        }
    }
    
    pcall(function()
        remotoPintura:InvokeServer(unpack(args))
    end)
end

-- ==========================================
-- 🔨 CONSTRUCCIÓN PRINCIPAL
-- ==========================================

function encontrarBloqueYSuID(posicionCFrame)
    local partesCercanas = workspace:GetPartBoundsInRadius(posicionCFrame.Position, 0.6)
    for _, parte in pairs(partesCercanas) do
        if parte:IsA("BasePart") and parte.Name ~= "Baseplate" and not parte.Parent:FindFirstChild("Humanoid") then
            local modeloPadre = parte.Parent
            if modeloPadre then
                -- Buscamos ID en el Padre (Modelo)
                local id = modeloPadre:GetAttribute("Id") or modeloPadre:GetAttribute("ID")
                if id then return parte, id end
            end
        end
    end
    return nil, nil
end

function redondearCFrame(cf)
    local x, y, z = cf.X, cf.Y, cf.Z
    return CFrame.new(x, y, z) * (cf - cf.Position)
end

function construirReal()
    if #datosGuardados == 0 then return notificar("⚠️ Nada para construir") end
    if not bloqueSeleccionado then return notificar("⚠️ Selecciona dónde construir") end
    
    -- Verificamos si tiene el cubo de pintura
    if not obtenerRemotoPintura() then
        notificar("⚠️ ADVERTENCIA: No tienes el 'PaintBucket' en inventario. No se pintará.")
        task.wait(2)
    end

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    procesoActivo = true
    notificar("🔨 Construyendo y Pintando...")
    
    local nuevoCentro = bloqueSeleccionado.CFrame + Vector3.new(0,1,0)
    local posOriginal = hrp.CFrame
    hrp.Anchored = true

    for i, data in pairs(datosGuardados) do
        if not procesoActivo then break end

        -- 1. Preparar Datos
        local relCF = CFrame.new(unpack(data.CF))
        local cframeFinal = nuevoCentro * relCF
        cframeFinal = redondearCFrame(cframeFinal)
        local sizeObjetivo = Vector3.new(unpack(data.Size))
        local colorObjetivo = Color3.new(unpack(data.Color))
        local nombreBloque = data.Name or "part_cube"

        -- 2. Teleport (Mantener cerca para que cargue)
        hrp.CFrame = cframeFinal * CFrame.new(0, 5, 0)
        RunService.Heartbeat:Wait()

        -- 3. PONER BLOQUE
        PlotSystem:InvokeServer("placeFurniture", nombreBloque, cframeFinal)

        -- 4. ESPERAR ID Y PARTE FÍSICA
        local parteFisica = nil
        local idEncontrado = nil
        local intentos = 0
        
        while not idEncontrado and intentos < 20 do -- Un poco más de tiempo
            task.wait(0.1)
            parteFisica, idEncontrado = encontrarBloqueYSuID(cframeFinal)
            intentos = intentos + 1
        end

        if idEncontrado and parteFisica then
            -- 5. ESCALAR (Usando ID)
            PlotSystem:InvokeServer("scaleFurniture", idEncontrado, cframeFinal, sizeObjetivo)
            
            -- 6. PINTAR (Usando Parte Física y PaintBucket)
            -- Pequeña pausa para asegurar que el servidor procesó el tamaño
            task.wait(0.05) 
            pintarBloque(parteFisica, colorObjetivo)

            -- Visual Verde (Éxito)
            local b = Instance.new("SelectionBox", parteFisica)
            b.Color3 = colorObjetivo -- Caja del color real
            b.Adornee = parteFisica; Debris:AddItem(b, 0.5)
        else
            warn("❌ Fallo bloque " .. i)
        end
        
        task.wait(0.1)
    end

    hrp.Anchored = false
    hrp.CFrame = posOriginal
    procesoActivo = false
    notificar("✅ Terminado")
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
loadBtn.Text = "📂 Cargar Archivo"; loadBtn.Size = UDim2.new(0.9,0,0,30); loadBtn.Position = UDim2.new(0.05,0,0.25,0); loadBtn.BackgroundColor3 = Color3.fromRGB(60,60,60); loadBtn.TextColor3 = Color3.new(1,1,1)
loadBtn.MouseButton1Click:Connect(function()
    local files = listfiles(CARPETA_PRINCIPAL)
    if #files > 0 then
        -- Cargar el último modificado o el último en lista
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
notificar("v17 Activa: Pintura y Rascacielos")
