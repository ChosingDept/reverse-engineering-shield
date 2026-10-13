# Embedded devices, firmware and IoT

Devices end up in strangers' hands, and firmware update files are often public downloads.

- Keep valuable logic and per-customer decisions in your cloud; the device collects data
  and executes commands.
- **Unique credentials per device**, provisioned at manufacturing, stored in a secure
  element or TPM when the hardware has one. Never one shared key across a fleet.
- Signed firmware with **secure boot**, and encrypted update images when the platform
  supports it. Verify signatures before flashing.
- Release builds without debug symbols, shells, UART consoles or JTAG/SWD left enabled.
- Remove factory test modes and default passwords before shipping.
- Revocation: the backend can disable a single device or a whole firmware version.

## Verify

Audit the update package you publish (for example, extracted from its archive) and
check by hand that it carries no symbol files, test keys or shared credentials:

```bash
scripts/audit.sh firmware-update-extracted/
```
