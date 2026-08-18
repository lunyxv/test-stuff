# ==================== LIB.PY CODE ====================
from pymem import Pymem
from pymem.process import is_64_bit, list_processes
from ctypes import windll
from psutil import pid_exists

Handle = None
PID = -1
baseAddr = None
pm = Pymem()

def DRP(address: int | str) -> int:
    if isinstance(address, str):
        address = int(address, 16)
    return int.from_bytes(pm.read_bytes(address, 8), "little")

def get_raw_processes():
    return [[
        i.cntThreads, i.cntUsage, i.dwFlags, i.dwSize,
        i.pcPriClassBase, i.szExeFile, i.th32DefaultHeapID,
        i.th32ModuleID, i.th32ParentProcessID, i.th32ProcessID
    ] for i in list_processes()]

def simple_get_processes():
    return [{"Name": i[5].decode(), "Threads": i[0], "ProcessId": i[9]} for i in get_raw_processes()]

def yield_for_program(program_name: str, printInfo: bool = True) -> bool:
    global PID, Handle, baseAddr, pm
    for proc in simple_get_processes():
        if proc["Name"] == program_name:
            pm.open_process_from_id(proc["ProcessId"])
            PID = proc["ProcessId"]
            Handle = windll.kernel32.OpenProcess(0x1038, False, PID)
            if printInfo:
                print('Roblox PID:', PID)
            for module in pm.list_modules():
                if module.name == "RobloxPlayerBeta.exe":
                    baseAddr = module.lpBaseOfDll
                    break
            if printInfo:
                print(f'Roblox base addr: {baseAddr:x}')
            return True
    return False

def is_process_dead() -> bool:
    return not pid_exists(PID)

def get_base_addr() -> int:
    return baseAddr

def setOffsets(nameOffset2: int, childrenOffset2: int):
    global nameOffset, childrenOffset
    nameOffset = nameOffset2
    childrenOffset = childrenOffset2

def ReadRobloxString(expected_address: int) -> str:
    string_count = pm.read_int(expected_address + 0x10)
    if string_count > 15:
        ptr = DRP(expected_address)
        return pm.read_string(ptr, string_count)
    return pm.read_string(expected_address, string_count)

def GetClassName(instance: int) -> str:
    ptr = pm.read_longlong(instance + 0x18)
    ptr = pm.read_longlong(ptr + 0x8)
    fl = pm.read_longlong(ptr + 0x18)
    if fl == 0x1F:
        ptr = pm.read_longlong(ptr)
    return ReadRobloxString(ptr)

def GetNameAddress(instance: int) -> int:
    return DRP(instance + nameOffset)

def GetName(instance: int) -> str:
    return ReadRobloxString(GetNameAddress(instance))

def GetChildren(instance: int) -> list:
    if not instance:
        return []
    children = []
    start = DRP(instance + childrenOffset)
    if start == 0:
        return []
    end = DRP(start + 8)
    current = DRP(start)
    for _ in range(9000):
        if current == end:
            break
        children.append(pm.read_longlong(current))
        current += 0x10
    return children

def FindFirstChild(instance: int, child_name: str) -> int:
    if not instance:
        return 0

    start = DRP(instance + childrenOffset)
    if start == 0:
        return 0
    end = DRP(start + 8)
    current = DRP(start)
    for _ in range(9000):
        if current == end:
            break
        child = pm.read_longlong(current)
        try:
            if GetName(child) == child_name:
                return child
        except:
            pass
        current += 0x10
    return 0

def FindFirstChildOfClass(instance: int, class_name: str) -> int:
    if not instance:
        return 0

    start = DRP(instance + childrenOffset)
    if start == 0:
        return 0
    end = DRP(start + 8)
    current = DRP(start)
    for _ in range(9000):
        if current == end:
            break
        child = pm.read_longlong(current)
        try:
            if GetClassName(child) == class_name:
                return child
        except:
            pass
        current += 0x10
    return 0

# ==================== VYRO.PY CODE ====================
from numpy import array, float32, linalg, cross, dot, reshape, sqrt as np_sqrt
from math import sqrt, pi
from ctypes import windll, byref, Structure, wintypes
from time import time, sleep
from threading import Thread
from requests import get
from subprocess import Popen, PIPE
from os import path
import dearpygui.dearpygui as dpg
from pymem.exception import ProcessError
import sys
import random
import string
import configparser
import os

pi180 = pi/180

aimbot_enabled = False
esp_enabled = False
esp_ignoreteam = False
esp_ignoredead = False
esp_show_lines = False
esp_show_box = False
esp_show_box2d = False
esp_show_hat = False
aimbot_ignoreteam = False
aimbot_ignoredead = False
aimbot_keybind = 2  
aimbot_mode = "Hold"  
aimbot_toggled = False  
waiting_for_keybind = False
injected = False
aimbot_sticky = False

aimbot_predict_x = 0.0
aimbot_predict_y = 0.0
prev_target_pos = [0, 0, 0]
prev_time = time()

aimbot_smooth = 0.5
prev_cframe = [1, 0, 0, 0, 1, 0, 0, 0, 1]

aimbot_kill_check = True
target_health = 0
last_target_address = 0
VK_CODES = {
    'Left Mouse': 1, 'Right Mouse': 2, 'Middle Mouse': 4,
    'X1 Mouse': 5, 'X2 Mouse': 6,
    'F1': 112, 'F2': 113, 'F3': 114, 'F4': 115, 'F5': 116, 'F6': 117,
    'F7': 118, 'F8': 119, 'F9': 120, 'F10': 121, 'F11': 122, 'F12': 123,
    'A': 65, 'B': 66, 'C': 67, 'D': 68, 'E': 69, 'F': 70, 'G': 71,
    'H': 72, 'I': 73, 'J': 74, 'K': 75, 'L': 76, 'M': 77, 'N': 78,
    'O': 79, 'P': 80, 'Q': 81, 'R': 82, 'S': 83, 'T': 84, 'U': 85,
    'V': 86, 'W': 87, 'X': 88, 'Y': 89, 'Z': 90,
    'Shift': 16, 'Ctrl': 17, 'Alt': 18, 'Space': 32,
    'Enter': 13, 'Tab': 9, 'Caps Lock': 20
}

def get_key_name(vk_code):
    for name, code in VK_CODES.items():
        if code == vk_code:
            return name
    return f"Key {vk_code}"

def generate_random_title():
    characters = string.ascii_letters + string.digits  
    return ''.join(random.choice(characters) for _ in range(24))

def title_changer():
    while True:
        try:
            new_title = generate_random_title()
            dpg.configure_item("Primary Window", label=new_title)
            dpg.set_viewport_title(new_title)
        except:
            pass  
        sleep(0.0000000000001)

def normalize(vec):
    norm = linalg.norm(vec)
    return vec / norm if norm != 0 else vec

def load_config():
    global aimbot_keybind, aimbot_mode, aimbot_predict_x, aimbot_predict_y
    global aimbot_ignoreteam, aimbot_ignoredead, aimbot_kill_check, aimbot_smooth
    global esp_show_lines, esp_show_box, esp_show_box2d, esp_show_hat
    global aimbot_sticky
    config = configparser.ConfigParser()
    if os.path.exists('config.ini'):
        config.read('config.ini')
        try:
            aimbot_keybind = config.getint('AIMBOT', 'keybind', fallback=2)
            aimbot_mode = config.get('AIMBOT', 'mode', fallback='Hold')
            aimbot_predict_x = config.getfloat('AIMBOT', 'predict_x', fallback=0.3)
            aimbot_predict_y = config.getfloat('AIMBOT', 'predict_y', fallback=0.2)
            aimbot_smooth = config.getfloat('AIMBOT', 'smooth', fallback=0.5)
            aimbot_ignoreteam = config.getboolean('AIMBOT', 'ignore_team', fallback=False)
            aimbot_ignoredead = config.getboolean('AIMBOT', 'ignore_dead', fallback=True)
            aimbot_kill_check = config.getboolean('AIMBOT', 'kill_check', fallback=True)
            aimbot_sticky = config.getboolean('AIMBOT', 'sticky_aim', fallback=False)
            esp_show_lines = config.getboolean('ESP', 'show_lines', fallback=False)
            esp_show_box = config.getboolean('ESP', 'show_box', fallback=False)
            esp_show_box2d = config.getboolean('ESP', 'show_box2d', fallback=False)
            esp_show_hat = config.getboolean('ESP', 'show_hat', fallback=False)
        except:
            pass

def save_config():
    config = configparser.ConfigParser()
    config['AIMBOT'] = {
        'keybind': str(aimbot_keybind),
        'mode': aimbot_mode,
        'predict_x': str(aimbot_predict_x),
        'predict_y': str(aimbot_predict_y),
        'smooth': str(aimbot_smooth),
        'ignore_team': str(aimbot_ignoreteam),
        'ignore_dead': str(aimbot_ignoredead),
        'kill_check': str(aimbot_kill_check),
        'sticky_aim': str(aimbot_sticky),
    }
    config['ESP'] = {
        'show_lines': str(esp_show_lines),
        'show_box': str(esp_show_box),
        'show_box2d': str(esp_show_box2d),
        'show_hat': str(esp_show_hat),
    }
    with open('config.ini', 'w') as f:
        config.write(f)

def cframe_look_at(from_pos, to_pos):
    from_pos = array(from_pos, dtype=float32)
    to_pos = array(to_pos, dtype=float32)
    look_vector = normalize(to_pos - from_pos)
    up_vector = array([0, 1, 0], dtype=float32)
    if abs(look_vector[1]) > 0.999:
        up_vector = array([0, 0, -1], dtype=float32)
    right_vector = normalize(cross(up_vector, look_vector))
    recalculated_up = cross(look_vector, right_vector)
    return look_vector, recalculated_up, right_vector

def load_offsets_with_retry():
    import json
    max_attempts = 3
    timeout = 5
    for attempt in range(max_attempts):
        try:
            print(f'Fetching fresh offsets from server (attempt {attempt+1}/{max_attempts})...')
            response = get('https://offsets.imtheo.lol/offsets.json', timeout=timeout)
            response.raise_for_status()
            offsets = response.json()
            try:
                with open('offsets_cache.json', 'w') as f:
                    json.dump(offsets, f)
                print('[+] Offsets cached successfully')
            except:
                pass
            return offsets
        except Exception as e:
            print(f'[!] Server fetch attempt {attempt+1} failed')
            if attempt < max_attempts - 1:
                sleep(0.5)
    if os.path.exists('offsets_cache.json'):
        try:
            print('[*] Using cached offsets as fallback...')
            with open('offsets_cache.json', 'r') as f:
                return json.load(f)
        except:
            print('[!] ERROR: Cache is corrupted!')
            return None
    print('[!] ERROR: Could not load offsets!')
    return None

print('=' * 50)
print('MARGIELA EXTERNAL v1.0')
print('=' * 50)
print('\nFetching offsets...')
offsets = load_offsets_with_retry()

if offsets is None:
    print('\n[!] FATAL ERROR: Could not load offsets!')
    input('Press any key to exit...')
    exit(1)

print('[+] Offsets loaded successfully\n')

# Convert new format to old format if needed
if 'Offsets' in offsets:
    o = offsets['Offsets']
    flat = {}
    
    if 'Instance' in o:
        flat['Name'] = str(o['Instance'].get('Name', 0))
        flat['Children'] = str(o['Instance'].get('ChildrenStart', 0))
    
    if 'FakeDataModel' in o:
        flat['FakeDataModelPointer'] = str(o['FakeDataModel'].get('Pointer', 0))
        flat['FakeDataModelToDataModel'] = str(o['FakeDataModel'].get('RealDataModel', 0))
    
    if 'DataModel' in o:
        flat['Workspace'] = str(o['DataModel'].get('Workspace', 0))
    
    if 'Workspace' in o:
        flat['Camera'] = str(o['Workspace'].get('CurrentCamera', 0))
    
    if 'Camera' in o:
        flat['CameraRotation'] = str(o['Camera'].get('Rotation', 0))
        flat['CameraPos'] = str(o['Camera'].get('Position', 0))
    
    if 'VisualEngine' in o:
        flat['VisualEnginePointer'] = str(o['VisualEngine'].get('Pointer', 0))
        flat['viewmatrix'] = str(o['VisualEngine'].get('ViewMatrix', 0))
    
    if 'Player' in o:
        flat['LocalPlayer'] = str(o['Player'].get('LocalPlayer', 0))
        flat['ModelInstance'] = str(o['Player'].get('ModelInstance', 0))
        flat['Team'] = str(o['Player'].get('Team', 0))
        flat['TeamColor'] = str(o['Player'].get('TeamColor', 0))
    
    if 'BasePart' in o:
        flat['Primitive'] = str(o['BasePart'].get('Primitive', 0))
    
    if 'Primitive' in o:
        flat['Position'] = str(o['Primitive'].get('Position', 0))
    
    if 'Humanoid' in o:
        flat['Health'] = str(o['Humanoid'].get('Health', 0))
    
    offsets = flat

setOffsets(int(offsets['Name'], 16), int(offsets['Children'], 16))

class RECT(Structure):
    _fields_ = [('left', wintypes.LONG), ('top', wintypes.LONG), ('right', wintypes.LONG), ('bottom', wintypes.LONG)]

class POINT(Structure):
    _fields_ = [('x', wintypes.LONG), ('y', wintypes.LONG)]

def find_window_by_title(title):
    return windll.user32.FindWindowW(None, title)

def get_client_rect_on_screen(hwnd):
    rect = RECT()
    if windll.user32.GetClientRect(hwnd, byref(rect)) == 0:
        return 0, 0, 0, 0
    top_left = POINT(rect.left, rect.top)
    bottom_right = POINT(rect.right, rect.bottom)
    windll.user32.ClientToScreen(hwnd, byref(top_left))
    windll.user32.ClientToScreen(hwnd, byref(bottom_right))
    return top_left.x, top_left.y, bottom_right.x, bottom_right.y

def world_to_screen_with_matrix(world_pos, matrix, screen_width, screen_height):
    vec = array([*world_pos, 1.0], dtype=float32)
    clip = dot(matrix, vec)
    if clip[3] == 0: return None
    ndc = clip[:3] / clip[3]
    if ndc[2] < 0 or ndc[2] > 1: return None
    x = (ndc[0] + 1) * 0.5 * screen_width
    y = (1 - ndc[1]) * 0.5 * screen_height
    return round(x), round(y)

baseAddr = 0
camAddr = 0
dataModel = 0
wsAddr = 0
camCFrameRotAddr = 0
plrsAddr = 0
lpAddr = 0
matrixAddr = 0
camPosAddr = 0
esp = None
target = 0

load_config()

def background_process_monitor():
    global baseAddr
    while True:
        if is_process_dead():
            while not yield_for_program("RobloxPlayerBeta.exe"):
                sleep(0.5)
            baseAddr = get_base_addr()
        sleep(0.1)

def address_validation_monitor():
    global dataModel, wsAddr, camAddr, lpAddr, matrixAddr, plrsAddr, injected
    last_check = time()
    check_interval = 0.5
    failed_checks = 0
    while True:
        try:
            current_time = time()
            if injected and (current_time - last_check) > check_interval:
                if not validate_addresses():
                    failed_checks += 1
                    if failed_checks >= 2:
                        print(f'[Monitor] Address validation failed {failed_checks} times - reinitializing...')
                        if reinit_addresses():
                            failed_checks = 0
                        else:
                            print('[Monitor] Reinit failed, will retry...')
                else:
                    failed_checks = 0
                last_check = current_time
            sleep(0.1)
        except Exception as e:
            print(f'[Monitor] Error: {e}')
            sleep(0.5)

Thread(target=background_process_monitor, daemon=True).start()
Thread(target=address_validation_monitor, daemon=True).start()

def init():
    global dataModel, wsAddr, camAddr, camCFrameRotAddr, plrsAddr, lpAddr, matrixAddr, camPosAddr, injected, offsets, esp, baseAddr
    try:
        print('\n' + '=' * 50)
        print('INJECTION PROCESS')
        print('=' * 50)
        print('\n[*] Waiting for Roblox process...')
        while not yield_for_program("RobloxPlayerBeta.exe", printInfo=False):
            sleep(0.5)
        print(f'[+] Roblox found, base address: {baseAddr:x}')
        fakeDatamodel = pm.read_longlong(baseAddr + int(offsets['FakeDataModelPointer'], 16))
        if fakeDatamodel == 0:
            raise Exception('FakeDataModel pointer is 0')
        dataModel = pm.read_longlong(fakeDatamodel + int(offsets['FakeDataModelToDataModel'], 16))
        if dataModel == 0:
            raise Exception('DataModel is 0')
        wsAddr = pm.read_longlong(dataModel + int(offsets['Workspace'], 16))
        if wsAddr == 0:
            raise Exception('Workspace is 0')
        camAddr = pm.read_longlong(wsAddr + int(offsets['Camera'], 16))
        if camAddr == 0:
            raise Exception('Camera is 0')
        camCFrameRotAddr = camAddr + int(offsets['CameraRotation'], 16)
        camPosAddr = camAddr + int(offsets['CameraPos'], 16)
        visualEngine = pm.read_longlong(baseAddr + int(offsets['VisualEnginePointer'], 16))
        if visualEngine == 0:
            raise Exception('VisualEngine is 0')
        matrixAddr = visualEngine + int(offsets['viewmatrix'], 16)
        plrsAddr = FindFirstChildOfClass(dataModel, 'Players')
        if plrsAddr == 0:
            raise Exception('Players folder not found')
        lpAddr = pm.read_longlong(plrsAddr + int(offsets['LocalPlayer'], 16))
        if lpAddr == 0:
            raise Exception('Local player is 0')
        test_read = pm.read_float(camPosAddr)
        print(f'[+] Camera position readable: {test_read}')
    except Exception as e:
        print(f'\n[!] Initialization failed: {str(e)}')
        return False

    try:
        if esp and esp.poll() is None:
            esp.stdin.write(f'addrs{lpAddr},{matrixAddr},{plrsAddr}\n')
            esp.stdin.flush()
            set_hat_color_red()
    except Exception as e:
        print(f'[!] ESP communication failed (ESP may not be running)')
    
    print('\n[+] Injected successfully!')
    print('=' * 50)
    injected = True
    def delayed_show():
        sleep(1)
        show_main_features()
    Thread(target=delayed_show, daemon=True).start()
    return True

def show_main_features():
    try:
        dpg.hide_item("loading_text")
    except:
        pass
    try:
        dpg.configure_item("main_features_text", default_value="✓ Injected!")
        dpg.show_item("main_features_text")
    except:
        pass
    try:
        dpg.configure_item("status_text", default_value="Injected ✓", color=(80, 200, 80))
    except:
        pass

def validate_addresses():
    global dataModel, wsAddr, camAddr, lpAddr, matrixAddr, plrsAddr, camPosAddr
    try:
        if dataModel == 0 or wsAddr == 0 or camAddr == 0 or lpAddr == 0 or matrixAddr == 0 or plrsAddr == 0:
            return False
        try:
            test_cam_x = pm.read_float(camPosAddr)
            test_cam_y = pm.read_float(camPosAddr + 4)
            test_cam_z = pm.read_float(camPosAddr + 8)
            if abs(test_cam_x) > 100000 or abs(test_cam_y) > 100000 or abs(test_cam_z) > 100000:
                return False
            if pm.read_longlong(lpAddr + 0x18) == 0:
                return False
            if pm.read_longlong(plrsAddr + 0x18) == 0:
                return False
            return True
        except:
            return False
    except:
        return False

def reinit_addresses():
    global dataModel, wsAddr, camAddr, camCFrameRotAddr, plrsAddr, lpAddr, matrixAddr, camPosAddr, baseAddr
    max_attempts = 3
    for attempt in range(max_attempts):
        try:
            if baseAddr == 0:
                sleep(0.5); continue
            fakeDatamodel = pm.read_longlong(baseAddr + int(offsets['FakeDataModelPointer'], 16))
            if fakeDatamodel == 0:
                sleep(0.5); continue
            dataModel = pm.read_longlong(fakeDatamodel + int(offsets['FakeDataModelToDataModel'], 16))
            if dataModel == 0:
                sleep(0.5); continue
            wsAddr = pm.read_longlong(dataModel + int(offsets['Workspace'], 16))
            if wsAddr == 0:
                sleep(0.5); continue
            camAddr = pm.read_longlong(wsAddr + int(offsets['Camera'], 16))
            if camAddr == 0:
                sleep(0.5); continue
            camCFrameRotAddr = camAddr + int(offsets['CameraRotation'], 16)
            camPosAddr = camAddr + int(offsets['CameraPos'], 16)
            visualEngine = pm.read_longlong(baseAddr + int(offsets['VisualEnginePointer'], 16))
            if visualEngine == 0:
                sleep(0.5); continue
            matrixAddr = visualEngine + int(offsets['viewmatrix'], 16)
            plrsAddr = FindFirstChildOfClass(dataModel, 'Players')
            if plrsAddr == 0:
                sleep(0.5); continue
            lpAddr = pm.read_longlong(plrsAddr + int(offsets['LocalPlayer'], 16))
            if lpAddr == 0:
                sleep(0.5); continue
            try:
                if esp and esp.poll() is None:
                    esp.stdin.write(f'addrs{lpAddr},{matrixAddr},{plrsAddr}\n')
                    esp.stdin.flush()
            except:
                pass
            print('[+] Addresses redetected successfully!')
            return True
        except Exception as e:
            print(f'Reinit attempt {attempt+1} failed: {e}')
            sleep(0.5)
    return False

def toogleEsp():
    try:
        if esp and esp.poll() is None:
            esp.stdin.write('toogle1\n')
            esp.stdin.flush()
    except:
        pass

def toogleIgnoreTeamEsp():
    try:
        if esp and esp.poll() is None:
            esp.stdin.write('toogle2\n')
            esp.stdin.flush()
    except:
        pass

def toogleIgnoreDeadEsp():
    try:
        if esp and esp.poll() is None:
            esp.stdin.write('toogle3\n')
            esp.stdin.flush()
    except:
        pass

def set_hat_color_red():
    try:
        if esp and esp.poll() is None:
            esp.stdin.write('hatcolor255,0,0\n')
            esp.stdin.flush()
    except:
        pass

if hasattr(sys, '_MEIPASS'):
    try:
        esp = Popen([
            path.abspath(path.join(sys._MEIPASS, '..', 'esp.exe')),
            str(int(offsets['ModelInstance'], 16)), str(int(offsets['Primitive'], 16)),
            str(int(offsets['Position'], 16)), str(int(offsets['Team'], 16)),
            str(int(offsets['TeamColor'], 16)), str(int(offsets['Health'], 16)),
            str(int(offsets['Name'], 16)), str(int(offsets['Children'], 16))
        ], stdin=PIPE, text=True, bufsize=1)
        print('[+] ESP process started (executable mode)')
    except Exception as e:
        print(f'[!] ESP failed to start')
        esp = None
else:
    try:
        esp = Popen([
            sys.executable, 'tracers.py',
            str(int(offsets['ModelInstance'], 16)), str(int(offsets['Primitive'], 16)),
            str(int(offsets['Position'], 16)), str(int(offsets['Team'], 16)),
            str(int(offsets['TeamColor'], 16)), str(int(offsets['Health'], 16)),
            str(int(offsets['Name'], 16)), str(int(offsets['Children'], 16))
        ], stdin=PIPE, text=True, bufsize=1)
        print('[+] ESP process started (script mode)')
    except Exception as e:
        print(f'[!] ESP failed to start')
        esp = None

def keybind_listener():
    global waiting_for_keybind, aimbot_keybind
    while True:
        if waiting_for_keybind:
            sleep(0.3)
            for vk_code in range(1, 256):
                windll.user32.GetAsyncKeyState(vk_code)
            key_found = False
            while waiting_for_keybind and not key_found:
                for vk_code in range(1, 256):
                    if windll.user32.GetAsyncKeyState(vk_code) & 0x8000:
                        if vk_code == 27:
                            waiting_for_keybind = False
                            dpg.configure_item("keybind_button", label=f"Keybind: {get_key_name(aimbot_keybind)}")
                            break
                        aimbot_keybind = vk_code
                        waiting_for_keybind = False
                        dpg.configure_item("keybind_button", label=f"Keybind: {get_key_name(vk_code)}")
                        key_found = True
                        break
                sleep(0.02)
        else:
            sleep(0.2)

Thread(target=keybind_listener, daemon=True).start()

def lerp_cframe(cframe1, cframe2, factor):
    return [cframe1[i] * (1 - factor) + cframe2[i] * factor for i in range(9)]

def normalize_cframe_vectors(cframe):
    right = array(cframe[0:3], dtype=float32)
    up = array(cframe[3:6], dtype=float32)
    look = array(cframe[6:9], dtype=float32)
    right_norm = linalg.norm(right)
    up_norm = linalg.norm(up)
    look_norm = linalg.norm(look)
    if right_norm > 0: right = right / right_norm
    if up_norm > 0: up = up / up_norm
    if look_norm > 0: look = look / look_norm
    return list(right) + list(up) + list(look)

def predict_position(current_pos, prev_pos, camera_pos, delta_time, predict_x, predict_y):
    if prev_pos is None or delta_time < 0.0001 or (predict_x == 0 and predict_y == 0):
        return current_pos
    try:
        curr = array(current_pos, dtype=float32)
        prev = array(prev_pos, dtype=float32)
        cam = array(camera_pos, dtype=float32)
        velocity = (curr - prev) / max(delta_time, 0.0001)
        distance = np_sqrt(dot(curr - cam, curr - cam))
        if distance < 0.1: return list(curr)
        bullet_time = distance / 250.0
        total_predict_time = bullet_time + 0.001
        predicted = curr + velocity * total_predict_time
        if predict_y > 0.01:
            gravity_drop = 9.81 * total_predict_time * total_predict_time * 0.5
            predicted[1] = predicted[1] - (gravity_drop * predict_y)
        return [
            curr[0] + (predicted[0] - curr[0]) * predict_x,
            curr[1] + (predicted[1] - curr[1]) * predict_y,
            curr[2] + (predicted[2] - curr[2]) * predict_x
        ]
    except:
        return current_pos

def check_target_kill():
    global target, target_health, last_target_address
    if target <= 0: return True
    try:
        parent_addr = pm.read_longlong(target - 0x20)
        char_addr = pm.read_longlong(parent_addr)
        humanoid = FindFirstChildOfClass(char_addr, 'Humanoid')
        if humanoid > 0:
            current_health = pm.read_float(humanoid + int(offsets['Health'], 16))
            target_health = current_health
            last_target_address = target
            return current_health > 0
    except:
        pass
    return True

def aimbotLoop():
    global target, aimbot_toggled, prev_target_pos, prev_time, target_health, last_target_address, aimbot_kill_check
    key_pressed_last_frame = False
    consecutive_errors = 0
    sticky_target = 0
    sticky_frames = 0
    
    while True:
        if aimbot_enabled:
            if not validate_addresses():
                consecutive_errors += 1
                if consecutive_errors > 5:
                    reinit_addresses()
                    consecutive_errors = 0
                sleep(0.1)
                continue
            consecutive_errors = 0
            key_pressed_this_frame = windll.user32.GetAsyncKeyState(aimbot_keybind) & 0x8000 != 0
            if aimbot_mode == "Toggle":
                if key_pressed_this_frame and not key_pressed_last_frame:
                    aimbot_toggled = not aimbot_toggled
                key_pressed_last_frame = key_pressed_this_frame
                should_aim = aimbot_toggled
            else:
                should_aim = key_pressed_this_frame
            if should_aim:
                if target > 0 and matrixAddr > 0:
                    if aimbot_kill_check and not check_target_kill():
                        target = 0
                    if target > 0:
                        try:
                            from_pos = [pm.read_float(camPosAddr), pm.read_float(camPosAddr+4), pm.read_float(camPosAddr+8)]
                            raw_to_pos = [pm.read_float(target), pm.read_float(target+4), pm.read_float(target+8)]
                            current_time = time()
                            delta_time = current_time - prev_time
                            if delta_time < 0.0001: delta_time = 0.0001
                            if delta_time > 0.5: delta_time = 0.016
                            prev_time = current_time
                            to_pos = raw_to_pos
                            if (aimbot_predict_x > 0.01 or aimbot_predict_y > 0.01) and delta_time > 0.00001:
                                to_pos = predict_position(current_pos=raw_to_pos, prev_pos=prev_target_pos,
                                    camera_pos=from_pos, delta_time=delta_time,
                                    predict_x=aimbot_predict_x, predict_y=aimbot_predict_y)
                            prev_target_pos = [raw_to_pos[0], raw_to_pos[1], raw_to_pos[2]]
                            
                            if prev_cframe == [1, 0, 0, 0, 1, 0, 0, 0, 1]:
                                try:
                                    prev_cframe = [
                                        pm.read_float(camCFrameRotAddr),
                                        pm.read_float(camCFrameRotAddr+4),
                                        pm.read_float(camCFrameRotAddr+8),
                                        pm.read_float(camCFrameRotAddr+12),
                                        pm.read_float(camCFrameRotAddr+16),
                                        pm.read_float(camCFrameRotAddr+20),
                                        pm.read_float(camCFrameRotAddr+24),
                                        pm.read_float(camCFrameRotAddr+28),
                                        pm.read_float(camCFrameRotAddr+32)
                                    ]
                                except:
                                    prev_cframe = [1, 0, 0, 0, 1, 0, 0, 0, 1]
                            
                            look, up, right = cframe_look_at(from_pos, to_pos)
                            new_cframe = [-right[0], up[0], -look[0], -right[1], up[1], -look[1], -right[2], up[2], -look[2]]
                            new_cframe = normalize_cframe_vectors(new_cframe)
                            
                            cframe_diff = sum(abs(new_cframe[i] - prev_cframe[i]) for i in range(9))
                            
                            if cframe_diff > 0.001:
                                if aimbot_smooth < 0.5:
                                    lerp_factor = 1.0 - (aimbot_smooth * 1.4)
                                else:
                                    lerp_factor = 0.3 - ((aimbot_smooth - 0.5) * 0.56)
                                
                                if cframe_diff < 0.01:
                                    lerp_factor *= 0.5
                                
                                lerp_factor = max(0.02, min(1.0, lerp_factor))
                                
                                smoothed_cframe = lerp_cframe(prev_cframe, new_cframe, lerp_factor)
                                prev_cframe = smoothed_cframe
                            else:
                                smoothed_cframe = prev_cframe
                            
                            pm.write_float(camCFrameRotAddr,    float(smoothed_cframe[0]))
                            pm.write_float(camCFrameRotAddr+4,  float(smoothed_cframe[1]))
                            pm.write_float(camCFrameRotAddr+8,  float(smoothed_cframe[2]))
                            pm.write_float(camCFrameRotAddr+12, float(smoothed_cframe[3]))
                            pm.write_float(camCFrameRotAddr+16, float(smoothed_cframe[4]))
                            pm.write_float(camCFrameRotAddr+20, float(smoothed_cframe[5]))
                            pm.write_float(camCFrameRotAddr+24, float(smoothed_cframe[6]))
                            pm.write_float(camCFrameRotAddr+28, float(smoothed_cframe[7]))
                            pm.write_float(camCFrameRotAddr+32, float(smoothed_cframe[8]))
                        except Exception as e:
                            consecutive_errors += 1
                            if consecutive_errors > 10:
                                target = 0
                                consecutive_errors = 0
                            sleep(0.01)
            else:
                if not aimbot_sticky or sticky_frames > 60:
                    sticky_target = 0
                    sticky_frames = 0
                
                target = 0
                consecutive_errors = 0
                prev_cframe = [1, 0, 0, 0, 1, 0, 0, 0, 1]
                hwnd_roblox = find_window_by_title("Roblox")
                if hwnd_roblox and matrixAddr > 0 and validate_addresses():
                    try:
                        left, top, right, bottom = get_client_rect_on_screen(hwnd_roblox)
                        matrix_flat = [pm.read_float(matrixAddr + i * 4) for i in range(16)]
                        view_proj_matrix = reshape(array(matrix_flat, dtype=float32), (4, 4))
                        lpTeam = pm.read_longlong(lpAddr + int(offsets['Team'], 16))
                        width = right - left
                        height = bottom - top
                        widthCenter = width/2
                        heightCenter = height/2
                        minDistance = float('inf')
                        
                        if aimbot_sticky and sticky_target > 0:
                            try:
                                obj_pos = array([pm.read_float(sticky_target), pm.read_float(sticky_target+4), pm.read_float(sticky_target+8)], dtype=float32)
                                screen_coords = world_to_screen_with_matrix(obj_pos, view_proj_matrix, width, height)
                                if screen_coords is not None:
                                    distance = sqrt((widthCenter - screen_coords[0])**2 + (heightCenter - screen_coords[1])**2)
                                    if distance < 300:
                                        target = sticky_target
                                        sticky_frames += 1
                                        minDistance = distance
                                    else:
                                        sticky_target = 0
                                        sticky_frames = 0
                                else:
                                    sticky_target = 0
                                    sticky_frames = 0
                            except:
                                sticky_target = 0
                                sticky_frames = 0
                        
                        if target == 0:
                            for v in GetChildren(plrsAddr):
                                if v != lpAddr:
                                    if not aimbot_ignoreteam or pm.read_longlong(v + int(offsets['Team'], 16)) != lpTeam:
                                        char = pm.read_longlong(v + int(offsets['ModelInstance'], 16))
                                        head = FindFirstChild(char, 'Head')
                                        hum = FindFirstChildOfClass(char, 'Humanoid')
                                        if head and hum:
                                            health = pm.read_float(hum + int(offsets['Health'], 16))
                                            if aimbot_ignoredead and health <= 0:
                                                continue
                                            primitive = pm.read_longlong(head + int(offsets['Primitive'], 16))
                                            targetPos = primitive + int(offsets['Position'], 16)
                                            obj_pos = array([pm.read_float(targetPos), pm.read_float(targetPos+4), pm.read_float(targetPos+8)], dtype=float32)
                                            screen_coords = world_to_screen_with_matrix(obj_pos, view_proj_matrix, width, height)
                                            if screen_coords is not None:
                                                distance = sqrt((widthCenter - screen_coords[0])**2 + (heightCenter - screen_coords[1])**2)
                                                if distance < minDistance:
                                                    minDistance = distance
                                                    target = targetPos
                                                    if aimbot_sticky:
                                                        sticky_target = targetPos
                                                        sticky_frames = 0
                    except:
                        consecutive_errors += 1
                        sleep(0.01)
                
                sleep(0.005)
        else:
            aimbot_toggled = False
            consecutive_errors = 0
            sleep(0.1)

def aimbot_callback(sender, app_data):
    global aimbot_enabled, aimbot_toggled, prev_cframe
    if not injected: return
    aimbot_enabled = app_data
    if not app_data:
        aimbot_toggled = False
        prev_cframe = [1, 0, 0, 0, 1, 0, 0, 0, 1]

def esp_callback(sender, app_data):
    global esp_enabled, esp_show_lines, esp_show_box, esp_show_box2d, esp_show_hat
    if not injected: return
    esp_enabled = app_data
    toogleEsp()
    if app_data:
        try:
            if esp and esp.poll() is None:
                esp.stdin.write(f'setlines{int(esp_show_lines)}\n')
                esp.stdin.flush()
                esp.stdin.write(f'setbox{int(esp_show_box)}\n')
                esp.stdin.flush()
                esp.stdin.write(f'setbox2d{int(esp_show_box2d)}\n')
                esp.stdin.flush()
                esp.stdin.write(f'sethat{int(esp_show_hat)}\n')
                esp.stdin.flush()
                set_hat_color_red()
        except:
            pass

def esp_ignoreteam_callback(sender, app_data):
    global esp_ignoreteam
    esp_ignoreteam = app_data
    toogleIgnoreTeamEsp()

def esp_ignoredead_callback(sender, app_data):
    global esp_ignoredead
    esp_ignoredead = app_data
    toogleIgnoreDeadEsp()

def esp_show_lines_callback(sender, app_data):
    global esp_show_lines
    esp_show_lines = app_data
    try:
        if esp and esp.poll() is None:
            esp.stdin.write(f'setlines{int(app_data)}\n')
            esp.stdin.flush()
    except:
        pass

def esp_show_box_callback(sender, app_data):
    global esp_show_box
    esp_show_box = app_data
    try:
        if esp and esp.poll() is None:
            esp.stdin.write(f'setbox{int(app_data)}\n')
            esp.stdin.flush()
    except:
        pass

def esp_show_box2d_callback(sender, app_data):
    global esp_show_box2d
    esp_show_box2d = app_data
    try:
        if esp and esp.poll() is None:
            esp.stdin.write(f'setbox2d{int(app_data)}\n')
            esp.stdin.flush()
    except:
        pass

def esp_show_hat_callback(sender, app_data):
    global esp_show_hat
    esp_show_hat = app_data
    try:
        if esp and esp.poll() is None:
            esp.stdin.write(f'sethat{int(app_data)}\n')
            esp.stdin.flush()
            if app_data:
                set_hat_color_red()
    except:
        pass

def aimbot_ignoreteam_callback(sender, app_data):
    global aimbot_ignoreteam
    aimbot_ignoreteam = app_data

def aimbot_ignoredead_callback(sender, app_data):
    global aimbot_ignoredead
    aimbot_ignoredead = app_data

def aimbot_kill_check_callback(sender, app_data):
    global aimbot_kill_check
    aimbot_kill_check = app_data

def aimbot_sticky_callback(sender, app_data):
    global aimbot_sticky
    aimbot_sticky = app_data

def aimbot_mode_callback(sender, app_data):
    global aimbot_mode, aimbot_toggled
    aimbot_mode = app_data
    if aimbot_mode == "Hold":
        aimbot_toggled = False

def keybind_callback():
    global waiting_for_keybind
    if not waiting_for_keybind:
        waiting_for_keybind = True
        dpg.configure_item("keybind_button", label="... (ESC to cancel)")

def inject_callback():
    init()

Thread(target=aimbotLoop, daemon=True).start()

dpg.create_context()

with dpg.theme() as theme_id:
    with dpg.theme_component(dpg.mvAll):
        dpg.add_theme_color(dpg.mvThemeCol_WindowBg, (10, 10, 10))
        dpg.add_theme_color(dpg.mvThemeCol_ChildBg, (15, 15, 15))
        dpg.add_theme_color(dpg.mvThemeCol_TitleBg, (120, 20, 20))
        dpg.add_theme_color(dpg.mvThemeCol_TitleBgActive, (160, 25, 25))
        dpg.add_theme_color(dpg.mvThemeCol_TitleBgCollapsed, (80, 15, 15))
        dpg.add_theme_color(dpg.mvThemeCol_Button, (140, 20, 20))
        dpg.add_theme_color(dpg.mvThemeCol_ButtonHovered, (180, 30, 30))
        dpg.add_theme_color(dpg.mvThemeCol_ButtonActive, (100, 15, 15))
        dpg.add_theme_color(dpg.mvThemeCol_FrameBg, (25, 25, 25))
        dpg.add_theme_color(dpg.mvThemeCol_FrameBgHovered, (35, 35, 35))
        dpg.add_theme_color(dpg.mvThemeCol_FrameBgActive, (45, 45, 45))
        dpg.add_theme_color(dpg.mvThemeCol_CheckMark, (220, 40, 40))
        dpg.add_theme_color(dpg.mvThemeCol_SliderGrab, (180, 30, 30))
        dpg.add_theme_color(dpg.mvThemeCol_SliderGrabActive, (220, 40, 40))
        dpg.add_theme_color(dpg.mvThemeCol_Separator, (120, 20, 20))
        dpg.add_theme_color(dpg.mvThemeCol_Border, (80, 20, 20))
        dpg.add_theme_color(dpg.mvThemeCol_Text, (210, 210, 210))
        dpg.add_theme_color(dpg.mvThemeCol_TextDisabled, (90, 90, 90))
        dpg.add_theme_color(dpg.mvThemeCol_Header, (120, 20, 20, 150))
        dpg.add_theme_color(dpg.mvThemeCol_HeaderHovered, (160, 25, 25, 180))
        dpg.add_theme_color(dpg.mvThemeCol_HeaderActive, (180, 30, 30, 200))
        dpg.add_theme_color(dpg.mvThemeCol_ScrollbarBg, (10, 10, 10))
        dpg.add_theme_color(dpg.mvThemeCol_ScrollbarGrab, (80, 15, 15))
        dpg.add_theme_color(dpg.mvThemeCol_ScrollbarGrabHovered, (120, 20, 20))
        dpg.add_theme_color(dpg.mvThemeCol_ScrollbarGrabActive, (160, 25, 25))
        dpg.add_theme_style(dpg.mvStyleVar_FramePadding, 4, 2)
        dpg.add_theme_style(dpg.mvStyleVar_WindowPadding, 6, 6)
        dpg.add_theme_style(dpg.mvStyleVar_ItemSpacing, 4, 3)
        dpg.add_theme_style(dpg.mvStyleVar_ItemInnerSpacing, 4, 3)
        dpg.add_theme_style(dpg.mvStyleVar_FrameRounding, 2)
        dpg.add_theme_style(dpg.mvStyleVar_GrabRounding, 2)
        dpg.add_theme_style(dpg.mvStyleVar_WindowRounding, 3)
        dpg.add_theme_style(dpg.mvStyleVar_ChildRounding, 2)
        dpg.add_theme_style(dpg.mvStyleVar_ButtonTextAlign, 0.5, 0.5)
        dpg.add_theme_style(dpg.mvStyleVar_ScrollbarSize, 8)

dpg.bind_theme(theme_id)

active_tab = "Aimbot"

def set_tab(tab_name):
    global active_tab
    active_tab = tab_name
    panel_map = {"Aimbot": "panel_aimbot", "Visuals": "panel_visuals", "Extras": "panel_extras"}
    for p in panel_map.values():
        dpg.hide_item(p)
    dpg.show_item(panel_map[tab_name])

def tab_aimbot(): set_tab("Aimbot")
def tab_visuals(): set_tab("Visuals")
def tab_extras(): set_tab("Extras")

with dpg.window(label="MARGIELA | v1.0", tag="Primary Window", width=400, height=335, no_resize=True, no_move=False, no_title_bar=False):

    dpg.add_text("", tag="main_features_text", show=False, color=(80, 200, 80))

    with dpg.group(horizontal=True):

        with dpg.child_window(width=80, height=285, border=True, tag="sidebar", no_scrollbar=True):
            dpg.add_spacer(height=2)
            dpg.add_button(label="Aimbot",  width=68, height=22, callback=tab_aimbot,  tag="btn_aimbot")
            dpg.add_spacer(height=2)
            dpg.add_button(label="Visuals", width=68, height=22, callback=tab_visuals, tag="btn_visuals")
            dpg.add_spacer(height=2)
            dpg.add_button(label="Extras",  width=68, height=22, callback=tab_extras,  tag="btn_extras")
            dpg.add_spacer(height=130)
            dpg.add_text("Made By", color=(90, 90, 90))
            dpg.add_text("xetsint", color=(160, 25, 25))

        dpg.add_spacer(width=4)

        with dpg.child_window(width=300, height=285, border=True, tag="content_area", no_scrollbar=True):

            with dpg.group(tag="panel_aimbot", show=True):
                dpg.add_text("-=Aimbot=-", color=(200, 35, 35))
                dpg.add_separator()
                dpg.add_spacer(height=2)
                dpg.add_checkbox(label="Aimbot",      default_value=aimbot_enabled,    callback=aimbot_callback,           tag="aimbot_toggle_checkbox")
                dpg.add_checkbox(label="Sticky Aim",  default_value=aimbot_sticky,     callback=aimbot_sticky_callback,    tag="sticky_aim_checkbox")
                dpg.add_checkbox(label="Kill Check",  default_value=aimbot_kill_check, callback=aimbot_kill_check_callback, tag="kill_check_check")
                dpg.add_checkbox(label="Ignore Dead", default_value=aimbot_ignoredead, callback=aimbot_ignoredead_callback, tag="aimbot_ignore_dead_checkbox")
                dpg.add_checkbox(label="Ignore Team", default_value=aimbot_ignoreteam, callback=aimbot_ignoreteam_callback, tag="ignore_team_check")
                dpg.add_spacer(height=3)
                dpg.add_separator()
                dpg.add_spacer(height=2)
                dpg.add_text("Keybind", color=(150, 150, 150))
                dpg.add_button(label=f"Keybind: {get_key_name(aimbot_keybind)}", width=-1, height=20, callback=keybind_callback, tag="keybind_button")
                dpg.add_spacer(height=2)
                dpg.add_text("Mode", color=(150, 150, 150))
                dpg.add_combo(["Hold", "Toggle"], default_value=aimbot_mode, callback=aimbot_mode_callback, tag="aimbot_mode_combo", width=-1)
                dpg.add_spacer(height=2)
                dpg.add_text("Smoothing", color=(150, 150, 150))
                def smooth_callback(sender, value):
                    global aimbot_smooth
                    aimbot_smooth = value
                dpg.add_slider_float(label="", default_value=aimbot_smooth, min_value=0.0, max_value=1.0, width=-1, callback=smooth_callback, tag="smooth_slider")
                dpg.add_spacer(height=2)
                dpg.add_text("Prediction X", color=(150, 150, 150))
                def predict_x_callback(sender, value):
                    global aimbot_predict_x
                    aimbot_predict_x = value
                dpg.add_slider_float(label="", default_value=aimbot_predict_x, min_value=0.0, max_value=1.0, width=-1, callback=predict_x_callback, tag="predict_x_slider")
                dpg.add_text("Prediction Y", color=(150, 150, 150))
                def predict_y_callback(sender, value):
                    global aimbot_predict_y
                    aimbot_predict_y = value
                dpg.add_slider_float(label="", default_value=aimbot_predict_y, min_value=0.0, max_value=1.0, width=-1, callback=predict_y_callback, tag="predict_y_slider")

            with dpg.group(tag="panel_visuals", show=False):
                dpg.add_text("-=Visuals=-", color=(200, 35, 35))
                dpg.add_separator()
                dpg.add_spacer(height=2)
                dpg.add_checkbox(label="ESP",         default_value=esp_enabled,     callback=esp_callback,             tag="esp_toggle_checkbox")
                dpg.add_checkbox(label="Show Lines",  default_value=esp_show_lines,  callback=esp_show_lines_callback,  tag="show_lines_checkbox")
                dpg.add_checkbox(label="Show Box",    default_value=esp_show_box,    callback=esp_show_box_callback,    tag="show_box_checkbox")
                dpg.add_checkbox(label="2D Box",      default_value=esp_show_box2d,  callback=esp_show_box2d_callback,  tag="show_box2d_checkbox")
                dpg.add_checkbox(label="Chinese Hat", default_value=esp_show_hat,    callback=esp_show_hat_callback,    tag="show_hat_checkbox")
                dpg.add_checkbox(label="Ignore Team", default_value=esp_ignoreteam,  callback=esp_ignoreteam_callback,  tag="esp_ignore_team_check")
                dpg.add_checkbox(label="Ignore Dead", default_value=esp_ignoredead,  callback=esp_ignoredead_callback,  tag="esp_ignore_dead_check")

            with dpg.group(tag="panel_extras", show=False):
                dpg.add_text("-=Extras=-", color=(200, 35, 35))
                dpg.add_separator()
                dpg.add_spacer(height=2)
                dpg.add_text("Status:", color=(150, 150, 150))
                dpg.add_text("Not injected", tag="status_text", color=(180, 180, 50))
                dpg.add_spacer(height=4)
                dpg.add_button(label="Re-Inject", width=-1, height=20, callback=inject_callback)

dpg.create_viewport(title='MARGIELA', width=420, height=365)
dpg.setup_dearpygui()
dpg.set_primary_window("Primary Window", True)

def auto_inject():
    def delayed_init():
        sleep(1)
        init()
    Thread(target=delayed_init, daemon=True).start()

auto_inject()
Thread(target=title_changer, daemon=True).start()
dpg.show_viewport()
dpg.start_dearpygui()
save_config()
dpg.destroy_context()
esp.terminate()
