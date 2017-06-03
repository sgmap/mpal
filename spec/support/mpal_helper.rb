def authenticate_as_project(project_id)
  session[:project_id] = project_id
end

def authenticate_as_user(user)
  if user.nil?
    allow(request.env["warden"]).to receive(:authenticate!).and_throw(:warden, { scope: :user })
    allow(controller).to receive(:current_user).and_return(nil)
  else
    allow(request.env["warden"]).to receive(:authenticate!).and_return(user)
    allow(controller).to receive(:current_user).and_return(user)
  end
end

def authenticate_as_agent(agent)
  if agent.nil?
    allow(request.env["warden"]).to receive(:authenticate!).and_throw(:warden, { scope: :agent })
    allow(controller).to receive(:current_agent).and_return(nil)
  else
    allow(request.env["warden"]).to receive(:authenticate!).and_return(agent)
    allow(controller).to receive(:current_agent).and_return(agent)
  end
end

def json(body)
  JSON.parse(body, symbolize_names: true)
end

def set_token_header(token)
  request.env['HTTP_AUTHORIZATION'] = "Token token=#{token}"
end
