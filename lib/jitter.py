#!/usr/bin/env python3
# augment_gpx.py
# Add jittered near points and midpoint points to a GPX track.
# Defaults: small jitter (3 m), uniform in a disk; outputs canonical GPX 1.1.

import argparse, random
import xml.etree.ElementTree as ET
from math import cos, sin, sqrt, pi
from datetime import datetime, timezone

# --- WGS-84 meters-per-degree approximations ---
def meters_per_deg_lat(phi_rad: float) -> float:
    return 111132.92 - 559.82 * cos(2*phi_rad) + 1.175 * cos(4*phi_rad) - 0.0023 * cos(6*phi_rad)

def meters_per_deg_lon(phi_rad: float) -> float:
    return 111412.84 * cos(phi_rad) - 93.5 * cos(3*phi_rad) + 0.118 * cos(5*phi_rad)

def parse_time_iso(s: str):
    if not s: return None
    # Accept …Z or offset forms
    try:
        if s.endswith("Z"):
            return datetime.fromisoformat(s.replace("Z", "+00:00"))
        return datetime.fromisoformat(s)
    except Exception:
        return None

def to_utc_z(dt: datetime|None) -> str|None:
    if dt is None: return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    else:
        dt = dt.astimezone(timezone.utc)
    return dt.strftime("%Y-%m-%dT%H:%M:%SZ")

def anyns_findall(elem, tag_local: str):
    # Find all elements with given local tag, ignoring namespace
    return elem.findall(f".//{{*}}{tag_local}")

def uniform_disc(max_r_m: float) -> tuple[float, float]:
    # Uniform in a disk of radius max_r_m
    u = random.random()
    r = max_r_m * sqrt(u)
    th = random.random() * 2*pi
    return (r*cos(th), r*sin(th))  # (dx east m, dy north m)

def gaussian_disc(sigma_m: float, cap_m: float) -> tuple[float, float]:
    # Isotropic Gaussian, clipped to cap_m
    from random import gauss
    dx, dy = gauss(0.0, sigma_m), gauss(0.0, sigma_m)
    n = sqrt(dx*dx + dy*dy)
    if n > cap_m and n > 0:
        scale = cap_m / n
        dx *= scale; dy *= scale
    return (dx, dy)

def build_gpx(root_tracks: list[list[dict]], orig_root: ET.Element) -> ET.ElementTree:
    GPX_NS = "http://www.topografix.com/GPX/1/1"
    XSI_NS = "http://www.w3.org/2001/XMLSchema-instance"
    SCHEMA_LOC = f"{GPX_NS} http://www.topografix.com/GPX/1/1/gpx.xsd"

    ET.register_namespace("", GPX_NS)
    ET.register_namespace("xsi", XSI_NS)

    gpx = ET.Element(f"{{{GPX_NS}}}gpx", {
        "version": "1.1",
        "creator": "augment_gpx.py",
        f"{{{XSI_NS}}}schemaLocation": SCHEMA_LOC
    })

    # Try to carry over a name if present
    name_text = None
    for n in anyns_findall(orig_root, "name"):
        if n.text and n.text.strip():
            name_text = n.text.strip(); break

    for idx, seg_pts in enumerate(root_tracks):
        trk = ET.SubElement(gpx, f"{{{GPX_NS}}}trk")
        ET.SubElement(trk, f"{{{GPX_NS}}}name").text = name_text or f"Augmented Track {idx+1}"
        seg = ET.SubElement(trk, f"{{{GPX_NS}}}trkseg")
        for p in seg_pts:
            trkpt = ET.SubElement(seg, f"{{{GPX_NS}}}trkpt", {
                "lat": f"{p['lat']:.8f}",
                "lon": f"{p['lon']:.8f}",
            })
            if p.get("ele") is not None:
                ET.SubElement(trkpt, f"{{{GPX_NS}}}ele").text = f"{p['ele']:.2f}"
            if p.get("time") is not None:
                ET.SubElement(trkpt, f"{{{GPX_NS}}}time").text = to_utc_z(p["time"])

    # Pretty print
    def indent(elem, level=0):
        i = "\n" + level*"  "
        if len(elem):
            if not elem.text or not elem.text.strip():
                elem.text = i + "  "
            for e in elem:
                indent(e, level+1)
            if not e.tail or not e.tail.strip():
                e.tail = i
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i

    indent(gpx)
    return ET.ElementTree(gpx)

def augment_track(points: list[dict], max_offset_m: float, dist_kind: str,
                  sigma_m: float, keep_original: bool, add_near: bool, add_mid: bool) -> list[dict]:
    out = []
    N = len(points)
    for i, a in enumerate(points):
        # A) original
        if keep_original:
            out.append(a.copy())

        # B) near jitter
        if add_near:
            phi = a["lat"] * pi/180.0
            mlat = meters_per_deg_lat(phi)
            mlon = meters_per_deg_lon(phi)
            if dist_kind == "uniform":
                dx, dy = uniform_disc(max_offset_m)
            else:
                dx, dy = gaussian_disc(sigma_m, max_offset_m)
            # dx east -> lon, dy north -> lat
            out.append({
                "lat": a["lat"] + dy / mlat,
                "lon": a["lon"] + dx / mlon,
                "ele": a["ele"],
                "time": a["time"],
            })

        # C) midpoint jitter
        if add_mid and i < N-1:
            b = points[i+1]
            mid_lat = 0.5*(a["lat"] + b["lat"])
            mid_lon = 0.5*(a["lon"] + b["lon"])
            mid_ele = None if (a["ele"] is None or b["ele"] is None) else 0.5*(a["ele"] + b["ele"])
            mid_time = None
            if a["time"] is not None and b["time"] is not None:
                mid_time = a["time"] + (b["time"] - a["time"])/2

            phi_m = mid_lat * pi/180.0
            mlat_m = meters_per_deg_lat(phi_m)
            mlon_m = meters_per_deg_lon(phi_m)
            if dist_kind == "uniform":
                dx2, dy2 = uniform_disc(max_offset_m)
            else:
                dx2, dy2 = gaussian_disc(sigma_m, max_offset_m)

            out.append({
                "lat": mid_lat + dy2 / mlat_m,
                "lon": mid_lon + dx2 / mlon_m,
                "ele": mid_ele,
                "time": mid_time,
            })
    return out

def main():
    ap = argparse.ArgumentParser(description="Augment a GPX by adding jittered points.")
    ap.add_argument("input", help="Input GPX file")
    ap.add_argument("output", help="Output GPX file")
    ap.add_argument("--max-offset-m", type=float, default=3.0, help="Max jitter radius in meters (default: 3.0)")
    ap.add_argument("--dist", choices=["uniform","gaussian"], default="uniform",
                    help="Jitter distribution (uniform disk or Gaussian clipped to radius)")
    ap.add_argument("--sigma-m", type=float, default=1.5, help="Sigma for Gaussian jitter (meters)")
    ap.add_argument("--seed", type=int, default=None, help="Random seed for reproducibility")
    ap.add_argument("--keep-original", action="store_true", default=True,
                    help="Include original points (default: on)")
    ap.add_argument("--no-keep-original", action="store_false", dest="keep_original")
    ap.add_argument("--near", action="store_true", default=True,
                    help="Add near-offset for each original point (default: on)")
    ap.add_argument("--no-near", action="store_false", dest="near")
    ap.add_argument("--mid", action="store_true", default=True,
                    help="Add midpoint-with-offset between consecutive points (default: on)")
    ap.add_argument("--no-mid", action="store_false", dest="mid")
    args = ap.parse_args()

    if args.seed is not None:
        random.seed(args.seed)

    # Parse input GPX (any namespace)
    tree = ET.parse(args.input)
    root = tree.getroot()

    # Collect tracks (concatenate per <trkseg>)
    tracks = []
    for trk in anyns_findall(root, "trk"):
        for seg in trk.findall(".//*"):
            if not seg.tag.endswith("trkseg"):
                continue
            pts = []
            for pt in seg:
                if not pt.tag.endswith("trkpt"):
                    continue
                lat = float(pt.attrib["lat"])
                lon = float(pt.attrib["lon"])
                ele = None
                tim = None
                for ch in pt:
                    if ch.tag.endswith("ele") and ch.text:
                        try: ele = float(ch.text)
                        except: ele = None
                    elif ch.tag.endswith("time") and ch.text:
                        tim = parse_time_iso(ch.text)
                pts.append({"lat": lat, "lon": lon, "ele": ele, "time": tim})
            if pts:
                tracks.append(pts)

    if not tracks:
        raise SystemExit("No <trkpt> found in input GPX.")

    # Augment each track
    aug_tracks = [augment_track(seg, args.max_offset_m, args.dist, args.sigma_m,
                                args.keep_original, args.near, args.mid)
                  for seg in tracks]

    # Build canonical GPX 1.1 and write
    out_tree = build_gpx(aug_tracks, root)
    out_tree.write(args.output, encoding="utf-8", xml_declaration=True)

    # Report
    orig = sum(len(t) for t in tracks)
    aug  = sum(len(t) for t in aug_tracks)
    print(f"Tracks: {len(tracks)} | original pts: {orig} | augmented pts: {aug}")
    print(f"Wrote: {args.output}")

if __name__ == "__main__":
    main()
