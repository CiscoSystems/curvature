# The Rest helper
#
@rest =
  postRequest: (url, data, callback) ->
    jQuery.ajax(
      url: url,
      type: 'post',
      contentType: 'application/json; charset=utf-8',
      data: JSON.stringify(data),
      success: (resp) =>
        callback(resp)
      error: (resp) =>
        @errorHandler(resp)
    )
    
  putRequest: (url, data, callback) ->
    jQuery.ajax(
      url: url,
      type: 'put',
      contentType: 'application/json; charset=utf-8',
      data: JSON.stringify(data),
      success: (resp) =>
        callback(resp)
      error: (resp) =>
        @errorHandler(resp)
    )

  putRequest: (url, data, callback) ->
    jQuery.ajax(
      url: url,
      type: 'put',
      contentType: 'application/json; charset=utf-8',
      data: JSON.stringify(data),
      success: (resp) =>
        callback(resp)
      error: (resp) =>
        @errorHandler(resp)
    )

  getRequest: (url, callback) ->
    jQuery.ajax(
      url: url,
      type: 'get'
      contentType: 'application/json; charset=utf-8',
      success: (resp) =>
        callback(resp)
      error: (resp) =>
        @errorHandler(resp)
    )
	
  deleteRequest: (url, callback) ->
    jQuery.ajax(
      url: url,
      type: 'delete'
      contentType: 'application/json; charset=utf-8',
      success: (resp) =>
        callback(resp)
      error: (resp) =>
        @errorHandler(resp)
    )

  errorHandler: (response) ->
    switch response.status
      when 401
        window.location = '/logout'
      when 0 then #DO NOTHING!
      else
        alert(response.responseText)
