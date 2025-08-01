class WorkflowVizHooks < Redmine::Hook::ViewListener
  # 워크플로우 편집 페이지 하단에 시각화 추가
  def view_workflows_edit_bottom(context = {})
    context[:controller].send(:render_to_string, {
      :partial => "hooks/workflow_visualization",
      :locals => context
    })
  end
end
