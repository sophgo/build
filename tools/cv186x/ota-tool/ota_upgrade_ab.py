#!/usr/bin/python3
# -*- coding: utf-8 -*-
import configparser
import os
import logging
import subprocess
import sys
import shutil
import hashlib

# ======================== CONFIGURATION ========================
CONF_PATH      = "/data/ota/config/ota.conf"
PROGRESS_PATH  = "/data/ota/progress/ota_progress.txt"
LOG_PATH       = "/data/ota/log/ota_upgrade.log"
CVI_AB_TOOL    = "/data/ota/tool/cvi_ab_boot"
SERIAL_PORT    = "/dev/console"

# ======================== LOG SETUP ========================
os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
os.makedirs(os.path.dirname(PROGRESS_PATH), exist_ok=True)
os.makedirs(os.path.dirname(CONF_PATH), exist_ok=True)

try:
    serial_fd = open(SERIAL_PORT, 'w')
except:
    serial_fd = sys.stdout

class ConsoleAndSerialHandler(logging.StreamHandler):
    def emit(self, record):
        msg = self.format(record)
        try:
            serial_fd.write(msg + "\n")
            serial_fd.flush()
        except:
            pass
        print(msg)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_PATH, encoding='utf-8'),
        ConsoleAndSerialHandler()
    ]
)
log = logging.getLogger("ota")

# ======================== MD5 校验 ========================
def calculate_md5(file_path):
    hash_md5 = hashlib.md5()
    try:
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_md5.update(chunk)
        return hash_md5.hexdigest()
    except Exception as e:
        log.info(f"calculate md5 failed: {str(e)}")
        return None

def verify_image_md5(img_path):
    md5_file = img_path + ".md5"
    if not os.path.exists(md5_file):
        log.info(f"[ERROR] MD5 file not found: {md5_file}")
        return False

    try:
        with open(md5_file, 'r') as f:
            expected_md5 = f.read().split()[0].strip()

        real_md5 = calculate_md5(img_path)
        if not real_md5:
            return False

        log.info(f"verify {os.path.basename(img_path)}:")
        log.info(f"expected md5: {expected_md5}")
        log.info(f"real md5:     {real_md5}")

        if real_md5 == expected_md5:
            log.info("[OK] MD5 check pass")
            return True
        else:
            log.info("[ERROR] MD5 check failed!")
            return False
    except Exception as e:
        log.info(f"verify md5 exception: {str(e)}")
        return False

# ======================== STATE HELPER ========================
def load_conf():
    c = configparser.ConfigParser()
    c.read(CONF_PATH, encoding='utf-8')
    return c

def write_state(state, target="", done=""):
    tmp = PROGRESS_PATH + ".tmp"
    content = f"{state}|{target}|{done}"
    try:
        with open(tmp, "w", encoding='utf-8') as f:
            f.write(content)
        os.replace(tmp, PROGRESS_PATH)
        log.info(f"write state: {content}")
    except Exception as e:
        log.info(f"write state failed: {str(e)}")

def read_state():
    if not os.path.exists(PROGRESS_PATH):
        return "IDLE", "", ""
    try:
        with open(PROGRESS_PATH, "r", encoding='utf-8') as f:
            data = f.read().strip().split("|")
        while len(data) < 3:
            data.append("")
        return data[0], data[1], data[2]
    except:
        return "IDLE", "", ""

def run_cmd(cmd):
    try:
        subprocess.run(cmd, shell=True, check=True, capture_output=True, text=True)
        return True
    except:
        return False

def sync_flash(img, dev):
    log.info(f"flashing image: {img} -> {dev}")
    if not run_cmd(f"dd if={img} of={dev} bs=4M status=none"):
        return False
    run_cmd("sync")
    return True


def clean_ota_service():
    service_dir = "/data/ota/service"
    try:
        if os.path.exists(service_dir):
            os.system("rm -rf /data/ota/service")
            log.info(f"[OK] Completely deleted directory: {service_dir}")
    except Exception as e:
        log.info(f"clean_ota_service err: {str(e)}")

# ======================== OTA CONTROL ========================
def ota_failed():
    log.info("OTA upgrade failed, stop service")
    write_state("FAILED")
    clean_ota_service()
    run_cmd("systemctl stop ota-upgrade-ab")
    run_cmd("systemctl disable ota-upgrade-ab")
    run_cmd("systemctl mask ota-upgrade-ab")

def ota_all_done():
    log.info("OTA all done, A and B are upgraded, stop service")
    write_state("ALL_DONE")
    clean_ota_service()
    run_cmd("systemctl stop ota-upgrade-ab")
    run_cmd("systemctl disable ota-upgrade-ab")
    run_cmd("systemctl mask ota-upgrade-ab")

# ======================== CVI AB SLOT ========================
def get_current_slot():
    c = load_conf()
    misc_dev = c["CVI_BOOT"]["misc_device"]
    cmd = f"{CVI_AB_TOOL} -d {misc_dev} -s"
    log.info(f"run cmd: {cmd}")

    try:
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        log.info(f"stdout: {res.stdout}")
        log.info(f"stderr: {res.stderr}")

        for line in res.stdout.splitlines():
            line = line.strip().lower()
            if "current active slot:" in line:
                slot = line.split(":")[-1].strip()
                log.info(f"detect current slot: {slot}")
                return slot

    except Exception as e:
        log.info(f"get_current_slot exception: {str(e)}")

    return None

def switch_slot():
    c = load_conf()
    misc_dev = c["CVI_BOOT"]["misc_device"]
    log.info("switching boot slot to the other one")
    cmd = f"{CVI_AB_TOOL} -d {misc_dev} -A"
    log.info(f"run cmd: {cmd}")
    return run_cmd(cmd)

def flash_target_slot(target):
    log.info(f"start flash target slot: {target}")
    c = load_conf()

    imgs = {
        "boot": c["UPGRADE"]["boot_image"],
        "rootfs": c["UPGRADE"]["rootfs_image"],
        "rootfs_rw": c["UPGRADE"]["rootfs_rw_image"]
    }

    parts = c["AB_PARTITIONS"]

    for name in ["boot", "rootfs", "rootfs_rw"]:
        dev_a, dev_b = parts[name].split(',')
        dev = dev_a if target == "a" else dev_b
        img = imgs[name]

        if not os.path.exists(img):
            log.info(f"image not found: {img}")
            return False

        # ==================== MD5 校验（关键） ====================
        if not verify_image_md5(img):
            log.info(f"[ERROR] {name} image verify failed")
            return False

        if not sync_flash(img, dev):
            return False
    return True

# ======================== MAIN ========================
def main():
    log.info("==================== OTA service start ====================")

    cur_slot = get_current_slot()
    log.info(f"current running slot: {cur_slot}")

    if not cur_slot or cur_slot not in ("a", "b"):
        log.info("get current slot failed, exit")
        ota_failed()
        return

    state, target_slot, done_str = read_state()
    done_slots = [x for x in done_str.split(",") if x]
    other_slot = "b" if cur_slot == "a" else "a"

    log.info(f"state: {state}")
    log.info(f"target_slot: {target_slot}")
    log.info(f"done_slots: {done_slots}")
    log.info(f"other_slot: {other_slot}")

    if state == "ALL_DONE":
        log.info("state is ALL_DONE, OTA finished, exit")
        ota_all_done()
        return
    if state == "FAILED":
        log.info("state is FAILED, exit")
        ota_failed()
        return

    # ==================== SCENE 1: reboot verify ====================
    if state == "WAIT_REBOOT":
        log.info("handle state WAIT_REBOOT, check boot result")

        if cur_slot == target_slot:
            log.info(f"boot success: cur_slot == target_slot ({cur_slot} == {target_slot})")

            if target_slot not in done_slots:
                done_slots.append(target_slot)
                log.info(f"add slot {target_slot} to done list")

            if "a" in done_slots and "b" in done_slots:
                log.info("both A and B upgraded, call ota_all_done")
                ota_all_done()
                return

            new_done = ",".join(done_slots)
            write_state("IDLE", "", new_done)
            state = "IDLE"
            done_str = new_done
            log.info(f"update state to IDLE, done_slots={new_done}")
        else:
            log.info(f"boot failed: rollback to old slot, cur={cur_slot}, target={target_slot}")
            ota_failed()
            return

    # ==================== SCENE 2: IDLE, upgrade other slot ====================
    if state == "IDLE":
        log.info(f"state is IDLE, prepare to upgrade other slot: {other_slot}")

        if not flash_target_slot(other_slot):
            log.info("flash target slot failed")
            ota_failed()
            return

        if not switch_slot():
            log.info("switch slot failed")
            ota_failed()
            return

        write_state("WAIT_REBOOT", other_slot, done_str)
        log.info("set state to WAIT_REBOOT, prepare reboot")
        run_cmd("sync && sleep 2 && reboot")
        return

    log.info("ota main loop end")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        log.info(f"OTA exception: {str(e)}")
        ota_failed()
