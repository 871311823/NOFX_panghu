import { useMemo } from 'react'
import { Activity } from 'lucide-react'
import type { AIModel, CompetitionTraderData } from '../../../types'
import { Language, t } from '../../../i18n/translations'
import { getModelIcon } from '../../ModelIcons'

interface ModelPerformanceSectionProps {
  language: Language
  configuredModels: AIModel[]
  traders?: CompetitionTraderData[]
  isLoading?: boolean
}

interface ModelSummary {
  modelId: string
  displayName: string
  traders: CompetitionTraderData[]
  runningCount: number
  totalPnL: number
  avgPnLPct: number
  lossTraders: CompetitionTraderData[]
}

export function ModelPerformanceSection({
  language,
  configuredModels,
  traders,
  isLoading,
}: ModelPerformanceSectionProps) {
  const modelMetaMap = useMemo(() => {
    const map = new Map<string, AIModel>()
    configuredModels?.forEach((model) => {
      const normalizedId = model.id?.toLowerCase()
      if (normalizedId) {
        map.set(normalizedId, model)
      }
      if (model.provider) {
        map.set(model.provider.toLowerCase(), model)
      }
    })
    return map
  }, [configuredModels])

  const summaries = useMemo<ModelSummary[]>(() => {
    if (!traders || traders.length === 0) return []

    const result = new Map<string, ModelSummary>()

    traders.forEach((trader) => {
      const modelKey = trader.ai_model?.toLowerCase() || 'unknown'
      const existing = result.get(modelKey)
      const modelMeta = modelMetaMap.get(modelKey)
      const displayName =
        modelMeta?.name || trader.ai_model?.toUpperCase() || 'UNKNOWN'

      if (!existing) {
        result.set(modelKey, {
          modelId: modelKey,
          displayName,
          traders: [trader],
          runningCount: trader.is_running ? 1 : 0,
          totalPnL: trader.total_pnl ?? 0,
          avgPnLPct: trader.total_pnl_pct ?? 0,
          lossTraders: (trader.total_pnl ?? 0) < 0 ? [trader] : [],
        })
        return
      }

      existing.traders.push(trader)
      if (trader.is_running) {
        existing.runningCount += 1
      }
      existing.totalPnL += trader.total_pnl ?? 0
      existing.avgPnLPct += trader.total_pnl_pct ?? 0
      if (trader.total_pnl !== undefined && trader.total_pnl < 0) {
        existing.lossTraders.push(trader)
      }
    })

    return Array.from(result.values())
      .map((summary) => ({
        ...summary,
        avgPnLPct:
          summary.traders.length > 0
            ? summary.avgPnLPct / summary.traders.length
            : 0,
      }))
      .sort((a, b) => a.avgPnLPct - b.avgPnLPct)
  }, [modelMetaMap, traders])

  const renderSkeleton = () => (
    <div className="space-y-3">
      {[0, 1].map((index) => (
        <div
          key={index}
          className="rounded border border-[#2B3139] p-3 md:p-4 animate-pulse"
          style={{ background: '#0B0E11' }}
        >
          <div className="h-4 w-1/2 skeleton mb-3"></div>
          <div className="h-3 w-1/3 skeleton"></div>
        </div>
      ))}
    </div>
  )

  return (
    <div className="binance-card p-3 md:p-4">
      <div className="flex items-center justify-between mb-3 md:mb-4">
        <h3
          className="text-base md:text-lg font-semibold flex items-center gap-2"
          style={{ color: '#EAECEF' }}
        >
          <Activity
            className="w-4 h-4 md:w-5 md:h-5"
            style={{ color: '#F0B90B' }}
          />
          {t('apiPerformance', language)}
        </h3>
        <span className="text-xs" style={{ color: '#848E9C' }}>
          {t('runningApis', language)}:{' '}
          <strong style={{ color: '#EAECEF' }}>{summaries.length}</strong>
        </span>
      </div>
      <p className="text-xs mb-4" style={{ color: '#848E9C' }}>
        {t('apiPerformanceSubtitle', language)}
      </p>

      {isLoading && summaries.length === 0 && renderSkeleton()}

      {!isLoading && summaries.length === 0 && (
        <div
          className="text-center py-6 md:py-8 rounded border border-dashed"
          style={{ borderColor: '#2B3139', background: '#0B0E11', color: '#848E9C' }}
        >
          {t('noActiveApis', language)}
        </div>
      )}

      {summaries.length > 0 && (
        <div className="space-y-3 md:space-y-4">
          {summaries.map((summary) => (
            <div
              key={summary.modelId}
              className="rounded border border-[#2B3139] p-3 md:p-4 transition-all duration-200"
              style={{ background: '#0B0E11' }}
            >
              <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 md:w-10 md:h-10 flex items-center justify-center rounded-full bg-[#151A1E] border border-[#2B3139]">
                    {getModelIcon(summary.modelId, {
                      width: 24,
                      height: 24,
                    }) || (
                      <span className="text-sm font-bold">
                        {summary.displayName?.[0] || '?'}
                      </span>
                    )}
                  </div>
                  <div>
                    <div
                      className="font-semibold text-sm md:text-base"
                      style={{ color: '#EAECEF' }}
                    >
                      {summary.displayName}
                    </div>
                    <div className="text-xs" style={{ color: '#848E9C' }}>
                      {summary.runningCount}/{summary.traders.length}{' '}
                      {t('traders', language)}
                    </div>
                  </div>
                </div>
                <div className="text-left md:text-right">
                  <div className="text-xs" style={{ color: '#848E9C' }}>
                    {t('pnl', language)}
                  </div>
                  <div
                    className="text-base font-bold mono"
                    style={{
                      color:
                        summary.avgPnLPct >= 0 ? '#0ECB81' : '#F6465D',
                    }}
                  >
                    {summary.avgPnLPct >= 0 ? '+' : ''}
                    {summary.avgPnLPct.toFixed(2)}%
                  </div>
                  <div className="text-xs mono" style={{ color: '#848E9C' }}>
                    {summary.totalPnL >= 0 ? '+' : ''}
                    {summary.totalPnL.toFixed(2)}
                  </div>
                </div>
              </div>

              {summary.lossTraders.length > 0 ? (
                <div className="mt-3">
                  <div className="text-xs mb-2" style={{ color: '#F6465D' }}>
                    {t('lossFocus', language)}
                  </div>
                  <div className="flex flex-wrap gap-2">
                    {summary.lossTraders.map((trader) => (
                      <div
                        key={trader.trader_id}
                        className="rounded px-3 py-2 text-xs md:text-sm"
                        style={{
                          background: 'rgba(246, 70, 93, 0.15)',
                          border: '1px solid rgba(246, 70, 93, 0.3)',
                          color: '#EAECEF',
                        }}
                      >
                        <div className="font-semibold">{trader.trader_name}</div>
                        <div className="mono" style={{ color: '#F6465D' }}>
                          {trader.total_pnl_pct?.toFixed(2) || '0.00'}% (
                          {trader.total_pnl?.toFixed(2) || '0.00'})
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ) : (
                <div
                  className="mt-3 text-xs font-medium"
                  style={{ color: '#0ECB81' }}
                >
                  {t('noLossForModel', language)}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

