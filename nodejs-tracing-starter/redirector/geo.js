export async function geolocate(ip) {
	if (isPrivateIP(ip)) {
		return { country: "Unknown", city: "Unknown" };
	}

	try {
		const response = await fetch(
			`http://ip-api.com/json/${ip}?fields=status,country,city,message`,
			{ signal: AbortSignal.timeout(3000) },
		);

		const data = await response.json();

		if (data.status === "fail") {
			return { country: "Unknown", city: "Unknown" };
		}

		return { country: data.country, city: data.city };
	} catch {
		return { country: "Unknown", city: "Unknown" };
	}
}

function isPrivateIP(ip) {
	return (
		ip === "127.0.0.1" ||
		ip === "::1" ||
		ip === "::ffff:127.0.0.1" ||
		ip.startsWith("10.") ||
		ip.startsWith("172.") ||
		ip.startsWith("192.168.")
	);
}
