module Ropenstack
  ## A wrapper class for Standard Error for Ropenstack Errors
  class RopenstackError < StandardError; end
  ## Error fired if openstack returns a Bad Request error
  class MalformedRequestError < RopenstackError; end
  ## Error fired if 403 Error returns from openstack 
  class UnauthorisedError < RopenstackError; end
  ## Error fired if the connection to openstack fails
  class TimeoutError < RopenstackError; end
  ## Error fired if a 404 error comes back from openstack
  class NotFoundError < RopenstackError; end
end
