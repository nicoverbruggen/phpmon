extension ShellEnvironment {
    func pathInstructionLines() -> [String] {
        return [
            phpMonitorBinPathExport,
            composerBinPathExport,
            homebrewBinPathExport
        ]
    }
}
