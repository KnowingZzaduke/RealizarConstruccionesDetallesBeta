local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
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
-- ⚙️ CONFIGURACIÓN
-- ==========================================
local CARPETA_PRINCIPAL = "MisConstruccionesRoblox"
local ALTURA_MAXIMA = 900
local TRANSPARENCIA_MOLDE = 0.5
local VELOCIDAD_VUELO = 350 -- Velocidad del Tween

if not isfolder(CARPETA_PRINCIPAL) then makefolder(CARPETA_PRINCIPAL) end

local datosGuardados = {}
local fantasmasCreados = {}
local bloqueSeleccionado = nil
local menuAbierto = true
local procesoActivo = false

local tool = Instance.new("Tool")
tool.RequiresHandle = false
tool.Name = "📐 Gestor V55 (Final Fly)"
tool.Parent = LocalPlayer.Backpack

local highlightBox = Instance.new("SelectionBox")
highlightBox.Color3 = Color3.fromRGB(0, 255, 100)
highlightBox.LineThickness = 0.05
highlightBox.Parent = workspace
highlightBox.Adornee = nil

-- ==========================================
-- 🖥️ GUI
-- ==========================================
if CoreGui:FindFirstChild("ClonadorProGUI") then CoreGui.ClonadorProGUI:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClonadorProGUI"
if syn and syn.protect_gui then syn.protect_gui(screenGui) elseif gethui then screenGui.Parent = gethui() else screenGui.Parent = CoreGui end

local toggleBtn = Instance.new("TextButton"); toggleBtn.Name = "ToggleMenu"; toggleBtn.Size = UDim2.new(0, 45, 0, 45); toggleBtn.Position = UDim2.new(0.02, 0, 0.4, 0); toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200); toggleBtn.Text = "📐"; toggleBtn.TextSize = 25; toggleBtn.TextColor3 = Color3.new(1,1,1); toggleBtn.Parent = screenGui; Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 10)

local mainFrame = Instance.new("Frame"); mainFrame.Name = "MainFrame"; mainFrame.Size = UDim2.new(0, 230, 0, 460);
mainFrame.Position = UDim2.new(0.15, 0, 0.25, 0); mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25); mainFrame.Parent = screenGui; Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

local topBar = Instance.new("Frame"); topBar.Size = UDim2.new(1, 0, 0, 35); topBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35); topBar.Parent = mainFrame; Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 10)
local title = Instance.new("TextLabel"); title.Text = "🏗️ V55 FLY+RECT"; title.Size = UDim2.new(0.8, 0, 1, 0); title.Position = UDim2.new(0.05, 0, 0, 0); title.BackgroundTransparency = 1; title.TextColor3 = Color3.fromRGB(0, 255, 100); title.Font = Enum.Font.GothamBold; title.TextSize = 14; title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = topBar
local closeMini = Instance.new("TextButton"); closeMini.Text = "-"; closeMini.Size = UDim2.new(0.15, 0, 1, 0); closeMini.Position = UDim2.new(0.85, 0, 0, 0); closeMini.BackgroundTransparency = 1; closeMini.TextColor3 = Color3.fromRGB(200, 200, 200); closeMini.TextSize = 20; closeMini.Font = Enum.Font.GothamBold; closeMini.Parent = topBar

local nameInput = Instance.new("TextBox"); nameInput.PlaceholderText = "Nombre archivo..."; nameInput.Size = UDim2.new(0.65, 0, 0, 30); nameInput.Position = UDim2.new(0.05, 0, 0.10, 0); nameInput.BackgroundColor3 = Color3.fromRGB(45, 45, 45); nameInput.TextColor3 = Color3.new(1,1,1); nameInput.Parent = mainFrame; Instance.new("UICorner", nameInput)
local btnSave = Instance.new("TextButton"); btnSave.Text = "💾"; btnSave.Size = UDim2.new(0.2, 0, 0, 30); btnSave.Position = UDim2.new(0.75, 0, 0.10, 0); btnSave.BackgroundColor3 = Color3.fromRGB(0, 120, 200); btnSave.TextColor3 = Color3.new(1,1,1); btnSave.Parent = mainFrame; Instance.new("UICorner", btnSave)

local scrollList = Instance.new("ScrollingFrame"); scrollList.Size = UDim2.new(0.9, 0, 0.25, 0); scrollList.Position = UDim2.new(0.05, 0, 0.19, 0); scrollList.BackgroundColor3 = Color3.fromRGB(35, 35, 35); scrollList.BorderSizePixel = 0; scrollList.Parent = mainFrame
local layoutFiles = Instance.new("UIListLayout"); layoutFiles.Padding = UDim.new(0, 4); layoutFiles.Parent = scrollList

local actionsFrame = Instance.new("Frame"); actionsFrame.Name = "ActionsFrame"; actionsFrame.Size = UDim2.new(0.9, 0, 0.52, 0); actionsFrame.Position = UDim2.new(0.05, 0, 0.46, 0); actionsFrame.BackgroundTransparency = 1; actionsFrame.Parent = mainFrame
local layoutActions = Instance.new("UIListLayout"); layoutActions.Padding = UDim.new(0, 6); layoutActions.SortOrder = Enum.SortOrder.LayoutOrder; layoutActions.Parent = actionsFrame
local statusLabel = Instance.new("TextLabel"); statusLabel.Size = UDim2.new(1,0,0,15); statusLabel.Position = UDim2.new(0,0,0.96,0); statusLabel.BackgroundTransparency = 1; statusLabel.TextColor3 = Color3.new(0.5,0.5,0.5); statusLabel.TextSize = 10; statusLabel.Parent = mainFrame

local function hacerArrastrable(frameDrag, frameMover)
    local dragging, dragInput, dragStart, startPos
    frameDrag.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = frameMover.Position end end)
    frameDrag.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then local delta = input.Position - dragStart; frameMover.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end
hacerArrastrable(topBar, mainFrame)
local function toggleGUI() menuAbierto = not menuAbierto; if menuAbierto then mainFrame:TweenPosition(UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, 0.25, 0), "Out", "Quad", 0.3, true) else mainFrame:TweenPosition(UDim2.new(mainFrame.Position.X.Scale, mainFrame.Position.X.Offset, 1.5, 0), "In", "Quad", 0.3, true) end end
toggleBtn.MouseButton1Click:Connect(toggleGUI); closeMini.MouseButton1Click:Connect(toggleGUI)

-- ==========================================
-- 🧠 FUNCIONES BASE
-- ==========================================
function notificar(texto) statusLabel.Text = texto; game:GetService("StarterGui"):SetCore("SendNotification", {Title="Builder V55", Text=texto, Duration=1.5}) end
function redondearCFrame(cf) local x, y, z = cf.X, cf.Y, cf.Z; return CFrame.new(x, y, z) * (cf - cf.Position) end

function obtenerNombreReal(p)
    if p.Parent and p.Parent:IsA("Model") and p.Parent.Name ~= "Model" then return p.Parent.Name end
    return "part_cube"
end

function encontrarBloqueYSuID(posicionCFrame)
    local partesCercanas = workspace:GetPartBoundsInRadius(posicionCFrame.Position, 0.8)
    for _, parte in pairs(partesCercanas) do
        if parte:IsA("BasePart") and parte.Name ~= "Baseplate" and not parte.Name:find("Ghost") and parte.Transparency < 1 then
            local modeloPadre = parte.Parent
            if modeloPadre then
                local id = modeloPadre:GetAttribute("Id") or modeloPadre:GetAttribute("ID")
                if id then return parte, id end
            end
        end
    end
    return nil, nil
end

function obtenerRotacionJugador()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local x, y, z = hrp.CFrame:ToEulerAnglesYXZ(); local rotacionSnap = math.round(y / (math.pi/2)) * (math.pi/2)
        return CFrame.Angles(0, rotacionSnap, 0)
    end
    return CFrame.new()
end

function limpiarFantasmas() for _, p in pairs(fantasmasCreados) do if p then p:Destroy() end end; fantasmasCreados = {} end

function obtenerPivoteSuperior(parteSuelo, rotacionExtra)
    if not parteSuelo then return CFrame.new() end
    local cfBase = parteSuelo.CFrame
    local cfSuperficie = cfBase * CFrame.new(0, parteSuelo.Size.Y / 2, 0)
    if rotacionExtra then return CFrame.new(cfSuperficie.Position) * rotacionExtra end
    return cfSuperficie
end

-- ==========================================
-- ✈️ SISTEMA DE MOVIMIENTO (VUELO TWEEN)
-- ==========================================
local function volarHacia(destino)
    local character = LocalPlayer.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local destinoFinal = destino
    local distancia = (root.Position - destinoFinal).Magnitude
    
    if distancia > 2 then
        local tiempo = distancia / VELOCIDAD_VUELO
        local tweenInfo = TweenInfo.new(tiempo, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(destinoFinal)})
        
        root.Anchored = false 
        root.Velocity = Vector3.zero
        tween:Play()
        tween.Completed:Wait()
    end
    
    -- Al llegar, anclar para estabilidad total (estilo V43)
    root.Velocity = Vector3.zero
    root.CFrame = CFrame.new(destinoFinal)
    root.Anchored = true 
end

-- ==========================================
-- 👀 VISUALIZADOR
-- ==========================================
function visualizarSinConstruir()
    if not bloqueSeleccionado then return notificar("⚠️ Selecciona destino") end
    if #datosGuardados == 0 then return notificar("⚠️ Archivo vacío") end
    
    limpiarFantasmas()
    notificar("👀 Visualizando...")
    
    local rotacionDeseada = obtenerRotacionJugador()
    local nuevoCentroCFrame = obtenerPivoteSuperior(bloqueSeleccionado, rotacionDeseada)
    
    for i, data in pairs(datosGuardados) do
        local relCF = CFrame.new(unpack(data.CF))
        local cframeFinal = redondearCFrame(nuevoCentroCFrame * relCF)
        local sizeObjetivo = Vector3.new(unpack(data.Size))
        
        local ghost = Instance.new("Part"); ghost.Name = "Ghost_Preview"; ghost.Size = sizeObjetivo; ghost.CFrame = cframeFinal
        ghost.Color = Color3.new(unpack(data.Color or {0.5,0.5,0.5})); ghost.Material = Enum.Material[data.Mat or "Plastic"]
        ghost.Transparency = TRANSPARENCIA_MOLDE; ghost.Anchored = true; ghost.CanCollide = false; ghost.Parent = workspace
        table.insert(fantasmasCreados, ghost)
    end
end

-- ==========================================
-- 🏗️ CONSTRUCCIÓN V55 (FLY + SORTED)
-- ==========================================
function construirV55()
    if not bloqueSeleccionado then return notificar("⚠️ Selecciona el PISO BASE") end
    if #datosGuardados == 0 then return notificar("⚠️ Archivo vacío") end
    
    limpiarFantasmas()
    
    local character = LocalPlayer.Character
    local hrp = character:WaitForChild("HumanoidRootPart")
    local posOriginalPlayer = hrp.CFrame -- Guardar posición para volver al final
    
    procesoActivo = true
    notificar("🚀 Construyendo (Vuelo)...")
    
    local rotacionDeseada = obtenerRotacionJugador()
    local nuevoCentroCFrame = obtenerPivoteSuperior(bloqueSeleccionado, rotacionDeseada)
    
    -- === ORDENAR: MAYOR A MENOR (VOLUMEN) ===
    table.sort(datosGuardados, function(a, b)
        local volA = a.Size[1] * a.Size[2] * a.Size[3]
        local volB = b.Size[1] * b.Size[2] * b.Size[3]
        return volA > volB -- Primero los gigantes
    end)

    hrp.Anchored = true

    for i, data in pairs(datosGuardados) do
        if not procesoActivo then break end

        local relCF = CFrame.new(unpack(data.CF))
        local cframeFinal = redondearCFrame(nuevoCentroCFrame * relCF)
        local sizeObjetivo = Vector3.new(unpack(data.Size))
        local nombreBloque = data.Type or "part_cube"

        -- Visualización (Ghost)
        local ghost = Instance.new("Part"); ghost.Name = "Ghost_Visual"; ghost.Size = sizeObjetivo; ghost.CFrame = cframeFinal
        ghost.Color = Color3.new(unpack(data.Color or {0.5,0.5,0.5})); ghost.Material = Enum.Material[data.Mat or "Plastic"]
        ghost.Transparency = TRANSPARENCIA_MOLDE; ghost.Anchored = true; ghost.CanCollide = false; ghost.Parent = workspace
        table.insert(fantasmasCreados, ghost)

        -- === MOVIMIENTO: VUELO ENCIMA DEL BLOQUE ===
        -- Volamos un poco arriba del objeto para verlo mientras se construye
        local objetivoVuelo = cframeFinal.Position + Vector3.new(0, 10, 0)
        volarHacia(objetivoVuelo)
        
        -- === LOGICA DE CONSTRUCCION Y ESPERA ===
        local bloqueConfirmado = false
        local intentos = 0
        
        while not bloqueConfirmado and intentos < 5 do
            intentos = intentos + 1
            local _, idCheck = encontrarBloqueYSuID(cframeFinal)
            
            if not idCheck then
                PlotSystem:InvokeServer("placeFurniture", nombreBloque, cframeFinal)
                
                -- Esperar a que el servidor cree el objeto (Wait for response)
                local esperaID = 0
                local nuevoID = nil
                while not nuevoID and esperaID < 15 do
                    task.wait(0.05)
                    local _, idDetectado = encontrarBloqueYSuID(cframeFinal)
                    nuevoID = idDetectado
                    esperaID = esperaID + 1
                end
                
                if nuevoID then
                    -- Escalar
                    PlotSystem:InvokeServer("scaleFurniture", nuevoID, cframeFinal, sizeObjetivo)
                    task.wait(0.4) -- Pausa técnica
                    
                    -- Verificación final
                    local _, checkFinal = encontrarBloqueYSuID(cframeFinal)
                    if checkFinal then bloqueConfirmado = true else task.wait(0.2) end
                else
                    task.wait(0.2)
                end
            else
                bloqueConfirmado = true
            end
        end
        task.wait(0.05)
    end

    procesoActivo = false
    hrp.Anchored = false
    hrp.CFrame = posOriginalPlayer -- Regresar al inicio
    notificar("✅ Construcción Finalizada")
    task.delay(4, function() limpiarFantasmas() end)
end

-- ==========================================
-- 🎯 COPIAR (RECTANGULAR AREA / SELECTOR LIMIT)
-- ==========================================
function copiarAreaSelector()
    if not bloqueSeleccionado then return notificar("⚠️ Selecciona el PISO BASE (Selector)") end
    
    datosGuardados = {}
    local sizePiso = bloqueSeleccionado.Size
    local cfPiso = bloqueSeleccionado.CFrame
    local origenCFrame = obtenerPivoteSuperior(bloqueSeleccionado)
    
    -- Límites definidos por el tamaño del bloque seleccionado (La herramienta de selección)
    local limiteX = sizePiso.X / 2
    local limiteZ = sizePiso.Z / 2
    
    -- Visualizar qué estamos copiando (Caja exacta del selector)
    local visualBox = Instance.new("SelectionBox")
    visualBox.Adornee = bloqueSeleccionado
    visualBox.Color3 = Color3.new(1, 0.5, 0)
    visualBox.Parent = workspace
    Debris:AddItem(visualBox, 2)

    local count = 0
    for _, p in pairs(workspace:GetDescendants()) do
        if p:IsA("BasePart") and p ~= bloqueSeleccionado and p.Name ~= "Baseplate" and not p.Name:find("Ghost") and not p.Parent:FindFirstChild("Humanoid") then
            -- Convertimos la posición de la parte al espacio local del piso
            local posRelativa = cfPiso:PointToObjectSpace(p.Position)
            
            -- Verificamos si está DENTRO del rectángulo del piso seleccionado
            local dentroX = math.abs(posRelativa.X) <= limiteX
            local dentroZ = math.abs(posRelativa.Z) <= limiteZ
            local alturaSobrePiso = posRelativa.Y - (sizePiso.Y / 2)
            
            if dentroX and dentroZ and alturaSobrePiso >= -0.5 and alturaSobrePiso <= ALTURA_MAXIMA then
                -- Guardar relativo al pivote superior
                local relGuardado = origenCFrame:Inverse() * p.CFrame
                table.insert(datosGuardados, {
                    Type = obtenerNombreReal(p), 
                    Size = {p.Size.X, p.Size.Y, p.Size.Z}, 
                    CF = {relGuardado:GetComponents()}, 
                    Color = {p.Color.R, p.Color.G, p.Color.B}, 
                    Mat = p.Material.Name
                })
                count = count + 1
            end
        end
    end
    notificar("✅ Copiado (Area Selector): " .. count)
end

function vaciarMemoria() datosGuardados = {}; notificar("♻️ Memoria vacía") end
function detenerProceso() procesoActivo = false; if LocalPlayer.Character then LocalPlayer.Character.HumanoidRootPart.Anchored = false end; notificar("🛑 Parando...") end

-- GUI Actions
function actualizarListaArchivos()
    for _, child in pairs(scrollList:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    local s, a = pcall(function() return listfiles(CARPETA_PRINCIPAL) end)
    if not s then return end
    for _, r in pairs(a) do
        local n = r:match("([^/]+)$")
        if n:sub(-5)==".json" then
            local f = Instance.new("Frame", scrollList); f.Size=UDim2.new(1,0,0,25); f.BackgroundTransparency=1
            local b = Instance.new("TextButton", f); b.Text=n:sub(1,-6); b.Size=UDim2.new(0.75,0,1,0); b.BackgroundColor3=Color3.fromRGB(60,60,60); b.TextColor3=Color3.new(1,1,1)
            b.MouseButton1Click:Connect(function() datosGuardados=HttpService:JSONDecode(readfile(r)); notificar("📂 "..#datosGuardados.." items") end)
            local d = Instance.new("TextButton", f); d.Text="X"; d.Size=UDim2.new(0.2,0,1,0); d.Position=UDim2.new(0.8,0,0,0); d.BackgroundColor3=Color3.fromRGB(150,0,0); d.TextColor3=Color3.new(1,1,1)
            d.MouseButton1Click:Connect(function() delfile(r); actualizarListaArchivos() end)
        end
    end
    scrollList.CanvasSize = UDim2.new(0,0,0,layoutFiles.AbsoluteContentSize.Y)
end

btnSave.MouseButton1Click:Connect(function() if #datosGuardados>0 and nameInput.Text~="" then writefile(CARPETA_PRINCIPAL.."/"..nameInput.Text..".json", HttpService:JSONEncode(datosGuardados)); notificar("💾 Guardado"); actualizarListaArchivos() end end)

local function crearBoton(t, c, o, f) local b = Instance.new("TextButton"); b.Text = t; b.Size = UDim2.new(1, 0, 0, 32); b.BackgroundColor3 = c; b.TextColor3 = Color3.new(1,1,1); b.LayoutOrder = o; b.Parent = actionsFrame; Instance.new("UICorner", b); b.MouseButton1Click:Connect(f) end

crearBoton("🎯 1. COPIAR ÁREA (K)", Color3.fromRGB(0, 150, 100), 1, copiarAreaSelector)
crearBoton("👁️ VISUALIZAR (V)", Color3.fromRGB(255, 170, 0), 2, visualizarSinConstruir)
crearBoton("🏗️ 2. CONSTRUIR V55 (B)", Color3.fromRGB(0, 120, 200), 3, construirV55)
crearBoton("🛑 PARAR (X)", Color3.fromRGB(200, 50, 50), 4, detenerProceso)
crearBoton("♻️ VACIAR MEMORIA (Z)", Color3.fromRGB(80, 80, 80), 5, vaciarMemoria)
crearBoton("🗑️ LIMPIAR GHOSTS", Color3.fromRGB(50, 50, 50), 6, limpiarFantasmas)

tool.Equipped:Connect(function(mouse) 
    actualizarListaArchivos()
    mouse.Button1Down:Connect(function() 
        if mouse.Target then 
            bloqueSeleccionado = mouse.Target
            highlightBox.Adornee = bloqueSeleccionado
            notificar("🎯 Área Fijada: " .. bloqueSeleccionado.Name) 
        end 
    end)
    mouse.KeyDown:Connect(function(key) 
        if key=="k" then copiarAreaSelector() 
        elseif key=="v" then visualizarSinConstruir()
        elseif key=="b" then construirV55() 
        elseif key=="x" then detenerProceso() 
        elseif key=="z" then vaciarMemoria() 
        end 
    end) 
end)
tool.Unequipped:Connect(function() highlightBox.Adornee = nil; bloqueSeleccionado = nil end)
actualizarListaArchivos()
notificar("✅ V55: Flight + Rect Copy")
