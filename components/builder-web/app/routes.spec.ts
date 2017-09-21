import { ExploreComponent } from "./explore/explore.component";
import { ProjectPageComponent } from "./project-page/ProjectPageComponent";
import { ProjectsPageComponent } from "./projects-page/ProjectsPageComponent";
import { SignInPageComponent } from "./sign-in-page/sign-in-page.component";
import { ProjectSettingsPageComponent } from "./project-settings-page/ProjectSettingsPageComponent";
import { routes } from "./routes";

describe("Routes", () => {

  function route(path) {
    return routes.find((r) => r.path === path);
  }

  describe("/", () => {
    it("routes to ExploreComponent", () => {
      let r = route("explore");
      expect(r.component).toBe(ExploreComponent);
    });
  });

  describe("/projects", () => {
    it("routes to ProjectsPageComponent", () => {
      let r = route("projects");
      expect(r.component).toBe(ProjectsPageComponent);
    });
  });

  describe("/projects/:origin/:name", () => {
    it("routes to ProjectPageComponent", () => {
      let r = route("projects/:origin/:name");
      expect(r.component).toBe(ProjectPageComponent);
    });
  });

  describe("/projects/:origin/:name/settings", () => {
    it("routes to ProjectSettingsPageComponent", () => {
      let r = route("projects/:origin/:name/settings");
      expect(r.component).toBe(ProjectSettingsPageComponent);
    });
  });

  describe("/sign-in", () => {
    it("routes to SignInPageComponent", () => {
      let r = route("sign-in");
      expect(r.component).toBe(SignInPageComponent);
    });
  });

  describe("non-existent routes", () => {
    it("redirect to /pkgs/core", () => {
      let r = route("*");
      let lastRoute = routes[routes.length - 1];
      expect(r.redirectTo).toBe("/pkgs/core");
      expect(lastRoute).toBe(r);
    });
  });
});
