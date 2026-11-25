// Five Pawns mockup: cards, swirl background, pixel blood, finger hands, card tilt.

const EN = ["Pawn", "Horse", "Cannon", "Chariot", "Elephant", "Advisor", "General"];
const FILE = ["pawn", "horse", "cannon", "chariot", "elephant", "advisor", "general"];

// Woodcut filter, injected once per page.
document.body.insertAdjacentHTML("afterbegin", `
<svg width="0" height="0" style="position:absolute" aria-hidden="true"><defs>
	<filter id="woodcut" x="-5%" y="-5%" width="110%" height="110%">
		<feTurbulence type="fractalNoise" baseFrequency="1.1" numOctaves="1" seed="3" result="t"/>
		<feColorMatrix in="t" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  -7 0 0 0 5.4" result="m"/>
		<feComposite in="SourceGraphic" in2="m" operator="in" result="ink"/>
		<feDisplacementMap in="ink" in2="t" scale="2.4" xChannelSelector="R" yChannelSelector="G"/>
	</filter>
</defs></svg>`);

// <div data-card="r3"> = Red Chariot (rank 0..6 as in the engine: 0 Pawn … 6 General).
// Mặt bài là asset đã duyệt (tools/build_card.py → assets/cards/png); tên tiếng Anh ở tooltip.
for (const el of document.querySelectorAll("[data-card]")) {
	const s = el.dataset.card[0], r = +el.dataset.card.slice(1);
	const name = `${s === "r" ? "Red" : "Black"} ${EN[r]}`;
	el.classList.add("card", "face");
	el.title = name;
	el.innerHTML = `<img src="../assets/cards/png/${s === "r" ? "red" : "black"}_${FILE[r]}.png" alt="${name}">`;
}
for (const el of document.querySelectorAll("[data-back]")) {
	el.classList.add("card", "back");
	el.setAttribute("role", "img");
	el.setAttribute("aria-label", "Face-down card");
}

// <span data-hand="pinky,ring"> → woodcut hand, lost fingers as bandaged stubs.
const FINGER_GEOM = { pinky: [8, 14, 18], ring: [18, 7, 25], middle: [28, 3, 29], index: [38, 7, 25] };
for (const el of document.querySelectorAll("[data-hand]")) {
	const lost = el.dataset.hand ? el.dataset.hand.split(",") : [];
	const size = +el.dataset.size || 64;
	let fingers = "";
	for (const f of ["pinky", "ring", "middle", "index"]) {
		const [x, y, h] = FINGER_GEOM[f];
		fingers += lost.includes(f)
			? `<rect x="${x - 1}" y="18" width="10" height="13" rx="2" fill="#eadcb4" stroke="#1b1310" stroke-width="1.8"/><path d="M${x - 1} 18 h10 v6 q-2.5 3 -5 1 q-2.5 2 -5 -1 z" fill="#7a120c"/>`
			: `<rect x="${x}" y="${y}" width="8" height="${h}" rx="4" fill="#e3cc9c" stroke="#1b1310" stroke-width="1.6"/>`;
	}
	const thumb = lost.includes("thumb")
		? `<rect x="47" y="31" width="8" height="8" rx="2" fill="#eadcb4" stroke="#1b1310" stroke-width="1.6" transform="rotate(-35 51 35)"/>`
		: `<rect x="47" y="24" width="8" height="20" rx="4" fill="#e3cc9c" stroke="#1b1310" stroke-width="1.6" transform="rotate(-35 51 34)"/>`;
	const left = 5 - lost.length;
	el.classList.add("hand-icon");
	el.setAttribute("role", "img");
	el.setAttribute("aria-label", `${left} of 5 fingers${lost.length ? `, lost: ${lost.join(", ")}` : ""}`);
	el.innerHTML = `<svg viewBox="0 0 64 56" width="${size}" height="${size * 56 / 64}">${fingers}${thumb}<rect x="7" y="27" width="41" height="26" rx="8" fill="#e3cc9c" stroke="#1b1310" stroke-width="1.6"/><path d="M14 40 h26 M14 46 h20" stroke="#1b1310" stroke-width="1" opacity=".35"/></svg>`;
}

function rng(seed) {
	let a = seed | 0;
	return () => {
		a = (a + 0x6d2b79f5) | 0;
		let t = Math.imul(a ^ (a >>> 15), 1 | a);
		t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
		return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
	};
}

// Swirl: per-pixel on a 240×135 canvas, posterised bands, scaled up pixelated.
// data-x (Death Ropes) speeds the swirl up during the Execution.
const PALETTES = {
	calm:  { stops: [[12, 8, 6], [30, 15, 10], [58, 19, 13], [92, 27, 17]], twist: 1.3, speed: 0.06, rings: 7 },
	table: { stops: [[10, 7, 5], [24, 12, 8], [44, 16, 11], [66, 21, 14]], twist: 1.6, speed: 0.08, rings: 8 },
	blood: { stops: [[16, 4, 3], [62, 9, 6], [122, 20, 13], [184, 38, 26]], twist: 2.8, speed: 0.12, rings: 11 },
};
for (const cv of document.querySelectorAll("canvas.swirl")) {
	const P = PALETTES[cv.dataset.mode || "calm"];
	const speed = P.speed * (1 + (+cv.dataset.x || 0) * 0.35);
	const W = (cv.width = 240), H = (cv.height = 135);
	const ctx = cv.getContext("2d");
	const img = ctx.createImageData(W, H);
	const lerp = (a, b, t) => a + (b - a) * t;
	const draw = (t) => {
		let p = 0;
		for (let y = 0; y < H; y++) {
			for (let x = 0; x < W; x++) {
				const u = (x - W / 2) / H, v = (y - H / 2) / H;
				const r = Math.hypot(u, v);
				const a = Math.atan2(v, u) + P.twist / (r + 0.3) + t * speed;
				let s = 0.65 * (Math.sin(a * 3 + r * P.rings - t * 0.6) * 0.5 + 0.5) + 0.35 * (Math.sin(a * 5 - r * 15 + t) * 0.5 + 0.5);
				s = Math.floor(s * 6) / 6 * Math.max(0, 1 - r * 0.75);
				const f = s * 3, i = Math.min(2, Math.floor(f)), k = f - i;
				img.data[p++] = lerp(P.stops[i][0], P.stops[i + 1][0], k);
				img.data[p++] = lerp(P.stops[i][1], P.stops[i + 1][1], k);
				img.data[p++] = lerp(P.stops[i][2], P.stops[i + 1][2], k);
				img.data[p++] = 255;
			}
		}
		ctx.putImageData(img, 0, 0);
	};
	const t0 = performance.now();
	const loop = (now) => { draw(3 + (now - t0) / 1000); requestAnimationFrame(loop); };
	draw(3);
	if (!matchMedia("(prefers-reduced-motion: reduce)").matches) requestAnimationFrame(loop);
}

// Pixel blood stain: merged discs make the pool, droplets spray around, darker rim like dried blood.
for (const cv of document.querySelectorAll("canvas.blood")) {
	const rand = rng(+cv.dataset.seed || 1);
	const W = cv.width, H = cv.height;
	const scale = +cv.dataset.scale || 8;
	cv.style.width = W * scale + "px";
	cv.style.height = H * scale + "px";
	const mask = new Uint8Array(W * H);
	const disc = (cx, cy, rad) => {
		for (let y = Math.floor(cy - rad); y <= cy + rad; y++)
			for (let x = Math.floor(cx - rad); x <= cx + rad; x++)
				if (x >= 0 && y >= 0 && x < W && y < H && (x - cx) ** 2 + (y - cy) ** 2 <= rad * rad) mask[y * W + x] = 1;
	};
	const cx = W / 2, cy = H / 2, R = Math.min(W, H) * 0.26;
	for (let i = 0; i < 9; i++) disc(cx + (rand() - 0.5) * R * 1.3, cy + (rand() - 0.5) * R, R * (0.35 + rand() * 0.45));
	for (let i = 0; i < 30; i++) {
		const a = rand() * Math.PI * 2, d = R * (1.05 + rand() * 1.7);
		disc(cx + Math.cos(a) * d, cy + Math.sin(a) * d * 0.75, Math.max(0.5, 2.2 * rand() * (1 - d / (R * 3))));
	}
	const ctx = cv.getContext("2d");
	const inside = (x, y) => x >= 0 && y >= 0 && x < W && y < H && mask[y * W + x];
	for (let y = 0; y < H; y++)
		for (let x = 0; x < W; x++) {
			if (!mask[y * W + x]) continue;
			const edge = !(inside(x - 1, y) && inside(x + 1, y) && inside(x, y - 1) && inside(x, y + 1));
			const n = rand();
			ctx.fillStyle = edge ? "#3a0503" : n < 0.06 ? "#9b2216" : n < 0.55 ? "#6a0f0a" : "#530a07";
			ctx.fillRect(x, y, 1, 1);
		}
}

// 3D tilt toward the pointer (the physical-card feel).
for (const c of document.querySelectorAll(".hand .card")) {
	c.addEventListener("pointermove", (e) => {
		const r = c.getBoundingClientRect();
		c.style.setProperty("--rx", `${(0.5 - (e.clientY - r.top) / r.height) * 18}deg`);
		c.style.setProperty("--ry", `${((e.clientX - r.left) / r.width - 0.5) * 22}deg`);
	});
	c.addEventListener("pointerleave", () => { c.style.removeProperty("--rx"); c.style.removeProperty("--ry"); });
}
