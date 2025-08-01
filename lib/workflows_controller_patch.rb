module WorkflowsControllerPatch
  def edit
    super
    # 시각화를 위한 로깅 (선택사항)
    Rails.logger.debug "Workflow Viz: Loaded workflow edit page"
  end
end

# 컨트롤러에 패치 적용
Rails.application.config.to_prepare do
  WorkflowsController.prepend(WorkflowsControllerPatch) unless WorkflowsController.ancestors.include?(WorkflowsControllerPatch)
end
