/************************************************************************
 * Imagine XI 2.0 mog-menu job change (module only)
 *
 * 2.0 launches a retail FFXiMain for the session (see client/ and
 * Launch Imagine XI 2.0.cmd). Official LSB process() is safe on that
 * client. This module only traces the 0x100 burst and strips MON/SOL
 * bits from outgoing 0x01B so a leftover Soldier-patched DLL cannot
 * treat unlock flags as a 24-job menu.
 ************************************************************************/

#include "map/utils/moduleutils.h"

#include "common/logging.h"
#include "common/timer.h"

#include "map/entities/char_entity.h"
#include "map/packets/basic.h"
#include "map/packets/c2s/0x100_myroom_job.h"

#include "enums/packet_s2c.h"

#include <chrono>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

namespace
{

constexpr auto TRACE_WINDOW        = std::chrono::seconds(12);
constexpr size_t MAX_TRACE_PACKETS = 256;
// Bits 0-22 only (subjob + WAR-RUN). MON=23 and SOL=24 crash a SOL-patched client.
constexpr uint32 RETAIL_JOB_UNLOCK_MASK = 0x007FFFFF;

struct PacketTrace
{
    timer::duration offset{};
    uint16          type{};
    uint16          size{};
};

struct JobChangeTrace
{
    uint32                   charId{};
    std::string              name;
    uint16                   zoneId{};
    uint8                    fromMain{};
    uint8                    fromSub{};
    uint8                    fromMainLvl{};
    uint8                    fromSubLvl{};
    uint8                    toMain{};
    uint8                    toSub{};
    timer::time_point        started{};
    bool                     dumped{};
    std::vector<PacketTrace> packets;
};

auto traces = std::unordered_map<uint32, JobChangeTrace>{};

auto wallClockStamp() -> std::string
{
    const auto now = std::chrono::system_clock::now();
    const auto tt  = std::chrono::system_clock::to_time_t(now);
    std::tm    local{};
#ifdef _WIN32
    localtime_s(&local, &tt);
#else
    localtime_r(&tt, &local);
#endif
    std::ostringstream out;
    out << std::put_time(&local, "%Y-%m-%d %H:%M:%S");
    return out.str();
}

auto fileStamp() -> std::string
{
    const auto now = std::chrono::system_clock::now();
    const auto tt  = std::chrono::system_clock::to_time_t(now);
    std::tm    local{};
#ifdef _WIN32
    localtime_s(&local, &tt);
#else
    localtime_r(&tt, &local);
#endif
    std::ostringstream out;
    out << std::put_time(&local, "%Y%m%d_%H%M%S");
    return out.str();
}

auto packetHint(uint16 type) -> std::string
{
    const auto name = magic_enum::enum_name(static_cast<PacketS2C>(type));
    if (!name.empty())
    {
        return std::string(name);
    }
    return "UNKNOWN";
}

auto sessionDir() -> std::filesystem::path
{
    std::filesystem::path dir = std::filesystem::path("log") / "crash_sessions";
    std::error_code       err;
    std::filesystem::create_directories(dir, err);
    return dir;
}

void dumpTrace(JobChangeTrace& trace, const std::string& kind)
{
    if (trace.dumped)
    {
        return;
    }
    trace.dumped = true;

    uint32 totalBytes = 0;
    auto   counts     = std::unordered_map<uint16, std::pair<uint32, uint32>>{};
    for (const auto& rec : trace.packets)
    {
        totalBytes += rec.size;
        auto& entry = counts[rec.type];
        entry.first += 1;
        entry.second += rec.size;
    }

    const auto dir      = sessionDir();
    const auto stamp    = fileStamp();
    const auto filename = fmt::format("jobchange_{}_{}_{}.txt", trace.name, stamp, kind);
    const auto path     = dir / filename;
    const auto latest   = dir / "jobchange_latest.txt";

    std::ostringstream body;
    body << "kind=" << kind << '\n';
    body << "time=" << wallClockStamp() << '\n';
    body << "char=" << trace.name << " id=" << trace.charId << '\n';
    body << "zone=" << trace.zoneId << '\n';
    body << "from_job=" << static_cast<int>(trace.fromMain) << '/' << static_cast<int>(trace.fromSub)
         << " from_lvl=" << static_cast<int>(trace.fromMainLvl) << '/' << static_cast<int>(trace.fromSubLvl) << '\n';
    body << "to_job=" << static_cast<int>(trace.toMain) << '/' << static_cast<int>(trace.toSub) << '\n';
    body << "packets_out=" << trace.packets.size() << '\n';
    body << "total_bytes=" << totalBytes << '\n';
    body << "elapsed_ms=" << std::chrono::duration_cast<std::chrono::milliseconds>(timer::now() - trace.started).count() << '\n';
    body << "counts:\n";

    for (const auto& [type, entry] : counts)
    {
        body << fmt::format("  0x{:03X} {} x{} size_sum={}\n", type, packetHint(type), entry.first, entry.second);
    }

    body << "timeline:\n";
    for (const auto& rec : trace.packets)
    {
        body << fmt::format("  +{}ms 0x{:03X} {} size={}\n",
                            std::chrono::duration_cast<std::chrono::milliseconds>(rec.offset).count(),
                            rec.type,
                            packetHint(rec.type),
                            rec.size);
    }

    const auto text = body.str();
    {
        std::ofstream file(path, std::ios::out | std::ios::trunc);
        if (file)
        {
            file << text;
        }
    }
    {
        std::ofstream file(latest, std::ios::out | std::ios::trunc);
        if (file)
        {
            file << text;
        }
    }

    ShowInfoFmt("Imagine XI 2.0: job change session {} char={} packets={} bytes={} -> {}",
                kind,
                trace.name,
                trace.packets.size(),
                totalBytes,
                path.generic_string());
}

void startTrace(CCharEntity* PChar, uint8 toMain, uint8 toSub)
{
    JobChangeTrace trace{};
    trace.charId      = PChar->id;
    trace.name        = PChar->getName();
    trace.zoneId      = static_cast<uint16>(PChar->getZone());
    trace.fromMain    = static_cast<uint8>(PChar->GetMJob());
    trace.fromSub     = static_cast<uint8>(PChar->GetSJob());
    trace.fromMainLvl = PChar->GetMLevel();
    trace.fromSubLvl  = PChar->GetSLevel();
    trace.toMain      = toMain;
    trace.toSub       = toSub;
    trace.started     = timer::now();
    traces[PChar->id] = std::move(trace);
}

void recordPacket(CCharEntity* PChar, const std::unique_ptr<CBasicPacket>& packet)
{
    auto it = traces.find(PChar->id);
    if (it == traces.end() || it->second.dumped)
    {
        return;
    }

    auto& trace = it->second;
    if (timer::now() - trace.started > TRACE_WINDOW)
    {
        return;
    }

    if (trace.packets.size() >= MAX_TRACE_PACKETS)
    {
        return;
    }

    PacketTrace rec{};
    rec.offset = timer::now() - trace.started;
    rec.type   = packet->getType();
    rec.size   = static_cast<uint16>(packet->getSize());
    trace.packets.push_back(rec);
}

void expireSurvivedTraces()
{
    const auto now = timer::now();
    for (auto it = traces.begin(); it != traces.end();)
    {
        if (!it->second.dumped && (now - it->second.started) > TRACE_WINDOW)
        {
            dumpTrace(it->second, "SURVIVED");
            it = traces.erase(it);
            continue;
        }
        if (it->second.dumped && (now - it->second.started) > TRACE_WINDOW)
        {
            it = traces.erase(it);
            continue;
        }
        ++it;
    }
}

void sanitizeJobInfoPacket(const std::unique_ptr<CBasicPacket>& packet)
{
    if (packet == nullptr || packet->getType() != static_cast<uint16>(PacketS2C::GP_SERV_COMMAND_JOB_INFO))
    {
        return;
    }

    packet->ref<uint32>(0x0C) &= RETAIL_JOB_UNLOCK_MASK;
}

} // namespace

class Ixi20JobChangeModule : public CPPModule
{
public:
    void OnInit() override
    {
        ShowInfo("Imagine XI 2.0: job change module loaded (official LSB packets, retail FFXiMain, strip SOL flags)");
    }

    auto OnIncomingPacket(MapSession* session, CCharEntity* PChar, CBasicPacket& packet) -> bool override
    {
        (void)session;

        if (PChar == nullptr || packet.getType() != static_cast<uint16>(PacketC2S::GP_CLI_COMMAND_MYROOM_JOB))
        {
            return false;
        }

        const auto* jobChange = packet.as<GP_CLI_COMMAND_MYROOM_JOB>();
        if (jobChange == nullptr)
        {
            return false;
        }

        const uint8 loadJob = jobChange->MainJobIndex > 0 ? jobChange->MainJobIndex : static_cast<uint8>(PChar->GetMJob());
        const uint8 toSub   = jobChange->SupportJobIndex;

        startTrace(PChar, loadJob, toSub);

        ShowInfoFmt("Imagine XI 2.0: job change {} id={} zone={} {}/{} L{}/{} -> {}/{} (official process, retail client)",
                    PChar->getName(),
                    PChar->id,
                    static_cast<uint16>(PChar->getZone()),
                    static_cast<int>(PChar->GetMJob()),
                    static_cast<int>(PChar->GetSJob()),
                    PChar->GetMLevel(),
                    PChar->GetSLevel(),
                    static_cast<int>(loadJob),
                    static_cast<int>(toSub));

        return false;
    }

    void OnPushPacket(CCharEntity* PChar, const std::unique_ptr<CBasicPacket>& packet) override
    {
        if (PChar == nullptr || packet == nullptr)
        {
            return;
        }

        sanitizeJobInfoPacket(packet);
        recordPacket(PChar, packet);
    }

    void OnCharZoneOut(CCharEntity* PChar) override
    {
        if (PChar == nullptr)
        {
            return;
        }

        auto it = traces.find(PChar->id);
        if (it == traces.end() || it->second.dumped)
        {
            return;
        }

        if (timer::now() - it->second.started <= TRACE_WINDOW)
        {
            dumpTrace(it->second, "SESSION_ENDED");
        }
        traces.erase(it);
    }

    void OnTimeServerTick() override
    {
        expireSurvivedTraces();
    }
};

REGISTER_CPP_MODULE(Ixi20JobChangeModule);
